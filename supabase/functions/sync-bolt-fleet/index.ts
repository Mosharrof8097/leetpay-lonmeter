import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const BOLT_AUTH_URL = "https://oidc.bolt.eu/token"
const BOLT_ORDERS_URL = "https://node.bolt.eu/fleet-integration-gateway/fleetIntegration/v1/getFleetOrders"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Identify Tenant
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error("Missing Authorization")

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(authHeader.replace('Bearer ', ''))
    if (authError || !user) throw new Error("Unauthorized access")
    const userId = user.id

    // 2. Fetch SaaS Integration Config with Dynamic Rules
    const { data: config, error: configError } = await supabaseClient
      .from('platform_configs')
      .select('*')
      .eq('user_id', userId)
      .eq('platform_name', 'bolt')
      .maybeSingle()

    if (configError || !config) throw new Error("Bolt integration not found in your settings")

    // --- DYNAMIC RULES EXTRACTION ---
    const clientId = (config.client_id || "").trim();
    const clientSecret = (config.client_secret || "").trim();
    let fleetId = (config.fleet_id || "").trim();
    
    // Percentages from DB
    const platformFeeRate = (config.platform_fee_percent || 20.0) / 100;
    const driverShareRate = (config.driver_share_percent || 45.0) / 100;
    const taxRate = (config.tax_percent || 5.66) / 100;
    const holidayPayRate = (config.holiday_pay_percent || 12.0) / 100;
    const pensionRate = (config.pension_percent || 4.5) / 100;

    if (clientId.length === 0 || clientSecret.length === 0) {
      throw new Error("Credentials cannot be empty");
    }

    // 3. HARDENED OIDC TOKEN EXCHANGE
    const basicAuth = btoa(`${clientId}:${clientSecret}`);
    const tokenBody = new URLSearchParams();
    tokenBody.append('grant_type', 'client_credentials');
    tokenBody.append('scope', 'fleet-integration:api');

    const authResponse = await fetch(BOLT_AUTH_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${basicAuth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'curl/7.68.0'
      },
      body: tokenBody.toString()
    })

    if (!authResponse.ok) throw new Error("Bolt Auth Failed");
    const { access_token } = await authResponse.json();

    // 3.5 AUTO-DISCOVERY (Scenario 3)
    if (!fleetId) {
      console.log(`[Discovery] Fleet ID missing. Attempting auto-discovery...`);
      const fleetDiscoveryUrl = "https://node.bolt.eu/fleet-integration-gateway/fleetIntegration/v1/getFleets";
      const discoveryRes = await fetch(fleetDiscoveryUrl, {
        headers: { 'Authorization': `Bearer ${access_token}`, 'User-Agent': 'curl/7.68.0' }
      });
      
      if (discoveryRes.ok) {
        const discoveryData = await discoveryRes.json();
        const firstFleet = discoveryData.data?.fleets?.[0];
        if (firstFleet) {
          fleetId = firstFleet.id.toString();
          console.log(`[Discovery] Found Fleet: ${firstFleet.name} (ID: ${fleetId})`);
          // Silently update DB for next time
          await supabaseClient.from('platform_configs').update({ fleet_id: fleetId }).eq('id', config.id);
        } else {
          throw new Error("No fleets found for these credentials");
        }
      } else {
        throw new Error("Fleet auto-discovery failed. Please enter Fleet ID manually.");
      }
    }

    // 4. SECURE DATA FETCHING
    const now = Math.floor(Date.now() / 1000)
    const startTs = now - (30 * 24 * 60 * 60) 

    const ordersResponse = await fetch(BOLT_ORDERS_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${access_token}`,
        'Content-Type': 'application/json',
        'User-Agent': 'curl/7.68.0'
      },
      body: JSON.stringify({
        company_ids: [Number(fleetId)],
        limit: 1000,
        start_ts: startTs,
        end_ts: now
      })
    })

    if (!ordersResponse.ok) throw new Error("Bolt Order API Failure");

    const ordersData = await ordersResponse.json()
    const orders = ordersData.data?.orders || []

    // 5. ATOMIC PERSISTENCE WITH DYNAMIC CALCULATION (Scenario 1 & 4)
    if (orders.length > 0) {
      const boltRecords = []
      const earningsRecords = []

      for (const o of orders) {
        const gross = o.order_price?.ride_price || 0;
        const tips = o.order_price?.tips || 0;
        
        // --- CASCADING SCENARIO LOGIC ---
        // 1. VAT
        const vatAmount = gross * taxRate;
        // 2. Platform Fee
        const platFeeAmount = gross * platformFeeRate;
        // 3. Total Revenue (Company Net)
        const totalRevenue = gross - (vatAmount + platFeeAmount);
        // 4. Driver Base Share
        const driverBaseShare = totalRevenue * driverShareRate;
        // 5. Final Net Payout to Driver
        const finalNetPayout = driverBaseShare + tips;

        // Metadata for employer costs
        const holidayPay = driverBaseShare * holidayPayRate;
        const socialFees = (driverBaseShare + holidayPay) * 0.3142; // Standard Swedish rate

        const date = new Date(o.order_created_timestamp * 1000);
        
        boltRecords.push({
          user_id: userId,
          order_reference: o.order_reference,
          driver_name: o.driver_name,
          order_created_timestamp: o.order_created_timestamp,
          order_status: o.order_status,
          price_total: gross,
          net_earnings: totalRevenue, // What company keeps before driver pay
          tax_6_percent: vatAmount,
          employer_fee_31_42: socialFees,
          net_payout_to_driver: finalNetPayout,
          raw_data: o
        });

        earningsRecords.push({
          user_id: userId,
          platform_id: 'bolt',
          reference: o.order_reference,
          driver_id: null,
          week_number: getWeekNumber(date),
          month: date.getMonth() + 1,
          year: date.getFullYear(),
          brutto: gross,
          netto: totalRevenue,
          moms: vatAmount,
          social_fees: socialFees,
          dricks: tips,
          platform_fee: platFeeAmount,
          applied_percentage: driverShareRate, // Snapshot current rate
        });
      }

      // Sync to bolt_trips
      const { error: boltError } = await supabaseClient
        .from('bolt_trips')
        .upsert(boltRecords, { onConflict: 'order_reference' })

      if (boltError) console.error(`[DB] Bolt Trips Error: ${boltError.message}`);

      // Sync to earnings (with conflict resolution on reference)
      const { error: earningsError } = await supabaseClient
        .from('earnings')
        .upsert(earningsRecords, { onConflict: 'user_id, platform_id, reference' })

      if (earningsError) console.error(`[DB] Earnings Error: ${earningsError.message}`);
    }

    return new Response(JSON.stringify({
      success: true,
      count: orders.length,
      message: `Sync successful for ${orders.length} trips`
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200
    })

  } catch (error: any) {
    console.error(`[Fatal Audit Error]: ${error.message}`);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500
    })
  }
})

// Helper for week numbers
function getWeekNumber(d: Date): number {
  d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  var yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  var weekNo = Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
  return weekNo;
}
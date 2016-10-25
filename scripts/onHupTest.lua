--               _   _           _____         _   
--    ___  _ __ | | | |_   _ _ _|_   _|__  ___| |_ 
--   / _ \| '_ \| |_| | | | | '_ \| |/ _ \/ __| __|
--  | (_) | | | |  _  | |_| | |_) | |  __/\__ \ |_ 
--   \___/|_| |_|_| |_|\__,_| .__/|_|\___||___/\__|
--                          |_|                    
-- wget --quiet -O - http://www.lemoda.net/games/figlet/figlet.cgi?text=onHupTest
--
-- Session & API BASED
--
api = freeswitch.API()

logToDisk               = session:getVariable("fsd_logToDisk")
debug                   = session:getVariable("fsd_debug")
myUuid                  = session:getVariable("uuid")
fsd_uuid                = session:getVariable("fsd_uuid")
fsd_use_vm              = session:getVariable("fsd_use_vm")
debugUuid               = fsd_uuid;  -- This Leg is the primary leg for debug
hangup_cause            = session:getVariable("hangup_cause")
fail_on_single_reject   = tostring( session:getVariable("fail_on_single_reject") )

modName = "onHupTest " .. myUuid;

-- ==========================================================
-- Shared Logging and Helper Functions 
--  Set modName, myUuid and debugUuid BEFORE this!!
-- ==========================================================
dofile("/etc/freeswitch/scripts/logAndHelper.lua")

-- --------------------------------------------
--  If Hangup Cause is one of the 'fail_on_single_reject' but NOT 'LOSE_RACE'
--   then kill all calls.  This kills calls in other threads too!
-- --------------------------------------------

	fsLogInfo( "*******  START of onHupTest.lua  -" .. hangup_cause .."- ******" )

    -- fsLogDebug( api:executeString('uuid_dump ' .. myUuid )); 

if ( ( fail_on_single_reject:match(hangup_cause) ~= nil) and ( hangup_cause ~= "LOSE_RACE") ) then
	fsLogInfo("** Match YES (hupall) == " .. hangup_cause .. " fsd_use_vm=" .. tostring(fsd_use_vm) )

    -- If we do not have VM then kill the origination side too
    if fsd_use_vm == nil or tonumber(fsd_use_vm) == 0 then
        fsLogInfo( "In HUP with fsd_use_vm nil or 0 " )
        api:executeString("hupall " .. hangup_cause .. " uuid " .. fsd_uuid )
    end

	-- api:executeString("hupall normal_clearing fsd_uuid_bleg_to_kill " .. fsd_uuid )
	api:executeString("hupall " .. hangup_cause .. " fsd_uuid " .. fsd_uuid )

elseif ( hangup_cause == "NORMAL_CLEARING" ) then
	fsLogInfo("** NORMAL_CLEARING  (hupall) == " .. hangup_cause )
    -- Kill both legs
	api:executeString("hupall " .. hangup_cause .. " fsd_uuid " .. fsd_uuid )
	-- api:executeString("hupall " .. hangup_cause .. " uuid " .. fsd_uuid )
else
	fsLogInfo("** Match NO == " .. hangup_cause )
end


-- =========================================================================
--
--  FS CO Functionality
--    _____ ____     ____ ___
--   |  ___/ ___|   / ___/ _ \
--   | |_  \___ \  | |  | | | |
--   |  _|  ___) | | |__| |_| |
--   |_|   |____/   \____\___/
--   
--
-- EXAMPLE: luarun fs_co.lua <user_part>  -- User Part is phone number or name 
--      FROM CLI
--          luarun fs_co.lua <fromTN> <toTN> 
--          luarun fs_co.lua 18014712099 18014712100
--   NOTE: This will ...
--
-- =========================================================================

api = freeswitch.API()

-- NOTE:  "session" is the inbound session

freeswitch.consoleLog("ERR", "** In fs_co.lua\n" )

-- ==========================================================
-- Initialize Variables
-- ==========================================================

-- local cops_co = "107.23.38.49:6060";
-- local cops_to = "107.23.38.49:6070";

local cops_ct = "107.23.38.49:6065";
local cops_tt = "107.23.38.49:6075";

local origTimeOut = 45;    -- 45 seconds 

local ttl = "** fs_co.main - "
local toNumber = "NOT_SET";

local fromTn = argv[1];
local toTn = argv[2];

local callID = "callID_Not_Set"
local callSource = "callSource_Not_Set"

local appData = {}

-- Use onNetTnList for both onNet TNs AND minutes to talk
local onNetTnList = {}

local onNetTnAlt = {}

-- Use onNetTnExt for extension Lists
local onNetTnExt = {}

 onNetTnAlt['17202791225'] = "18014712099"


onNetTnList['180147120991'] = 20
 onNetTnExt['180147120991'] = "0001,0003"
onNetTnList['17202791225'] = 30
onNetTnList['17202797684'] = 50
 onNetTnExt['17202797684'] = "001"
onNetTnList['17202797891'] = 10
onNetTnList['17202799791'] = 1
onNetTnList['17203813446'] = 50
-- onNetTnExt['17203813446'] = "0004,0012"

-- 17202797684_002


-- ==========================================================
-- Helper Functions 
-- ==========================================================

	-- appData['is_gogii_tptn'] = isGogiiTN( fromTN, toTN ) -- determines if at least on TN is Gogii owned
	-- appData['minutes'] = inTnOnNetTime( fromTN )
	-- appData['tptn'] = returnGogiiTN( toTN, fromTN )   -- us toTN first for app2app cases
	-- appData['timeToRing'] = origTimeOut
	-- appData['ext'] = returnGogiiExtensions( toTN )  -- return list or nil
	-- appData['app2app'] = isApp2App( fromTN, toTN )
	-- appData['enoughMinute'] = isEnoughMinutes( appData.minutes )
	-- appData['inbound'] = isInbound( toTN )
	-- appData['srcNum'] = fromTN
	-- appData['dstNum'] = toTN
	-- appData['callID'] = callID
	-- appData['callSource'] = callSource
	-- appData['obClientArray'] = nil

function doCall( fromTN, toTN, callID, callSource )

	gogiiApiLookup( fromTN, toTN, callID, callSource )  -- setup appData array to use

	if appData.isGogiiTn == 0 then -- Check to see if either TN is valid Gogii TN
		playNoValidTN()
	elseif appData.app2app == 0 and appData.enoughMinute == 0 then
		playNoMoney()
	else  -- Let the call go through

		if appData.app2app == 1 then
			freeswitch.consoleLog("WARNING", ttl .. "App2App Call \n" )
			appData.gw = cops_ct
			doPstnCall()
		elseif callSource == "softphone" then  -- Not App2App so terminate on PSTN
			freeswitch.consoleLog("WARNING", ttl .. "App -> PSNT Call \n" )
			appData.gw = cops_tt
			doPstnCall()
		elseif callSource == "pstn" then  -- Not App2App so terminate on Client
			freeswitch.consoleLog("INFO", ttl .. "PSTN -> App Call \n" )
			appData.gw = cops_ct
			doPstnCall()
		else
		end
	end

	-- Translate TN 

	-- determine where to send call  -- Client Termination or Trunking Termination

end 

function do_ObCall( toNumber, gw )   -- Old - get rid of this

end


function doClientCall( )   -- Terminate to Client/App

end 

function doPstnCall( )   -- Terminate to PSTN

	ttl = "** fs.doPstnCall - "

	freeswitch.consoleLog("INFO", ttl .. "Start \n" )

		-- "{ignore_early_media=true,originate_timeout=%s}sofia/fs_co_6060/%s@%s",
	obSessionString = string.format(
		"{origination_caller_id_number=%s,originate_timeout=%s}sofia/fs_co_6060/%s@%s",
		appData.srcNum, origTimeOut, appData.dstNum, appData.gw )

	freeswitch.consoleLog("INFO", ttl .. "obSessionString = " .. obSessionString .. "\n")

	local ObSession = freeswitch.Session( obSessionString )

	if ObSession:ready() then
		freeswitch.consoleLog("INFO", ttl .. "Session IS Ready\n")
		ObSession:streamFile("/etc/freeswitch/sounds/en/us/callie/directory/8000/dir-letters_of_person_name.wav");

		if session ~= nil then  -- session == inbound call
			if session:ready() then
				freeswitch.consoleLog("INFO", ttl .. "Bridging Sessions\n")
				freeswitch.bridge(session, ObSession)
			else
				freeswitch.consoleLog("INFO", ttl .. "session is NOT Ready\n")
			end
		else
			freeswitch.consoleLog("INFO", ttl .. "session is NIL \n")

		end 
	else
		freeswitch.consoleLog("INFO", ttl .. "ObSession is NOT Ready\n")
	end

	freeswitch.consoleLog("INFO", ttl .. "End \n" )
end

-- ==========================================================
-- Back End Simulation Section
-- ==========================================================

-- ----------------------------------------------------------
-- This section simulates the API call to Gogii back end.  
--   It can be replaced later with JSON call
-- 
--       is_gogii_tptn=1 - 1=true 0=false
--       forwarding=0
--       minutes=6 - how long they can talk
--       tptn=4056228545
--       timeToRing=30
--       voiceMail=0 - 0=disabled - Not current offered
--       timeToForward=30  - Not current offered
--       timeToVM=30  - Not current offered
--       ext=0006 - List of comma delimited extensions
--       0006,0007,0008
--       app2app=0
--       enoughMinute=1  - 1=true/0=false
--       inbound=1  - 1=true/0=false
--       deviceRegistered=1  - 1=true/0=false
--       is911=0  - 1=true/0=false
--       callSource=pstn  - PSTN or softphone
--       srcNum=3479658848
--       dstNum=4056228545 
--       callId=1762480045_114626145@4.55.2.227
--       carrier=PSTN - will say Level3, or other carrier
--       freeCall=false - not used for production
-- ----------------------------------------------------------

-- ----------------------------------------------------------
-- gogiiApiLookup()
--    Fills In the appData data structure
-- ----------------------------------------------------------
function gogiiApiLookup( fromTN, toTN, callID, callSource )

	appData['isGogiiTn'] = isGogiiTN( fromTN, toTN ) -- determines if at least on TN is Gogii owned

	if callSource == "pstn" then 
		appData['minutes'] = isTnOnNetTime( toTN )
	else
		appData['minutes'] = isTnOnNetTime( fromTN )
	end
	appData['tptn'] = returnGogiiTN( toTN, fromTN )   -- us toTN first for app2app cases
	appData['timeToRing'] = origTimeOut
	appData['ext'] = returnGogiiExtensions( toTN )  -- return list or nil
	appData['app2app'] = isApp2App( fromTN, toTN )
	appData['enoughMinute'] = isEnoughMinutes( appData.minutes )
	appData['inbound'] = isInbound( toTN )
	appData['srcNum'] = fromTN
	appData['dstNum'] = toTN
	appData['callID'] = callID
	appData['callSource'] = callSource
	appData['obClientArray'] = nil

	createObClientArray()

	if appData.obClientArray ~= nil then appData.dstNum = appData.obClientArray[1] end

	printAppData()
	printObClientArray()


end

function printAppData()
	pOutString = "\n=====App Data=====\n"
	for k, v in pairs(appData) do
		pOutString=string.format("%sk=%s, v=%s\n", pOutString, tostring(k), tostring(v))
	end
	pOutString=string.format("%s%s\n", pOutString, printObClientArray() )
	freeswitch.consoleLog("INFO", pOutString )
end

function printObClientArray()
	pOutString = "=====ObClientArray Data=====\n"

	if appData['obClientArray'] ~= nil then
		for k, v in pairs( appData['obClientArray'] ) do
			pOutString=string.format("%sk=%s, v=%s\n", pOutString, tostring(k), tostring(v))
		end
	end
	return pOutString
end

function createObClientArray()
	if appData['ext'] ~= nil then   -- has extensions
		local extArray = appData.ext:split(",")
		appData['obClientArray'] = {}
		
		for k, extension in pairs(extArray) do
			table.insert(appData['obClientArray'], appData.dstNum .. "_" .. extension) 
		end
	else 
		appData['obClientArray'] = nil
	end
end

function string:split(sep)
        local sep, fields = sep or ",", {}
        local pattern = string.format("([^%s]+)", sep)
        self:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end

function isTnOnNet( tn ) -- return 1 if tn is in onNetTnList else return 0
	return onNetTnList[tn] and 1 or 0
end

function isTnOnNetTime( tn ) -- return time if tn is in onNetTnList else return 0
	return onNetTnList[tn] and onNetTnList[tn] or 0
end

function isGogiiTN( fromTN, toTN )
	return isTnOnNet( fromTN ) == 1 and isTnOnNet( fromTN ) or isTnOnNet( toTN )
end

function returnGogiiTN( fromTN, toTN )
	return isTnOnNet( fromTN ) == 1 and fromTN or ( isTnOnNet( toTN ) == 1 and toTN or "" )
end

function returnGogiiExtensions( toTN )
	return isTnOnNet( toTN ) == 1 and ( onNetTnExt[ toTN ] and onNetTnExt[ toTN ] or nil ) or nil
end

function isApp2App( fromTN, toTN )
	return isTnOnNet( fromTN ) == 1 and ( isTnOnNet( toTN ) == 1 and 1 or 0 ) or 0
end

function isEnoughMinutes( minutes )
	return minutes > 10 and 1 or 0
end

function isInbound( toTN )
	return isTnOnNet( toTN ) == 1 and 1 or 0
end


-- ==========================================================
-- Play Error Messages
-- ==========================================================


function playNoValidTN()
	freeswitch.consoleLog("ERR", "\n\n******* playNoValidTN ********\n\n" );
	playPrompt( "input good prompt here")
end

function playNoMoney()
	freeswitch.consoleLog("ERR", "\n\n******* playNoMoney ********\n\n" );
	playPrompt( "input good prompt here")
end

function playTnCanNotTakeCalls()
	freeswitch.consoleLog("ERR", "\n\n******* playTnCanNotTakeCalls ********\n\n" );
	playPrompt( "input good prompt here")
end

function playPrompt( prompt )
	freeswitch.consoleLog("ERR", "\n\n******* playPrompt ********\n\n" );

	if session:ready() then

		-- session:preAnswer();

		-- answer the call
		session:answer();

		-- sleep a second
		session:sleep(1000);

		-- play a file
		session:streamFile("/etc/freeswitch/sounds/en/us/callie/directory/8000/dir-letters_of_person_name.wav");

		-- hangup
		session:hangup();

	else
		freeswitch.consoleLog("ERR", ttl .. " Sessioin NOT Ready\n" );
	end

end


-- ==========================================================
-- Main
-- ==========================================================


-- JSON URL  - curl http://38.119.57.196/callrouter/ json


ttl = "** fs_co.main - "

if (session ~= nil ) then
	-- ---------------------------------------------------
	-- This section is for being called via application
	-- ---------------------------------------------------

	freeswitch.consoleLog("INFO", ttl .. " session ~= nil \n" )


	local fromTN = session:getVariable("sip_from_user_stripped");
	local toTN = session:getVariable("destination_number");
	local callSource = session:getVariable("callSource");
	local callID = session:getVariable("sip_call_id");

	-- Make sure fromTN does not have extension on it !! 
	fromTN = string.match(fromTN, "(.-)_") and string.match(fromTN, "(.-)_") or fromTN

	session:execute("ring_ready")  -- Sends 180 to Originator
	-- session:execute("callUUID", "jamesCallUUID")
	-- session:execute("api_hangup_hook", "hupall normal_clearing callUUID jamesCallUUID")

	doCall( fromTN, toTN, callID, callSource )

else
	-- ---------------------------------------------------
	-- This section is for testing via CLI
	-- ---------------------------------------------------

	freeswitch.consoleLog("INFO", ttl .. " session IS nil \n" )
	if ( fromTn == "18015556666" ) then
		freeswitch.consoleLog("INFO", ttl .. " 18015556666 \n" )
		do_co( "18014712100" )

	elseif fromTn == "3" then
		freeswitch.consoleLog("INFO", ttl .. " 3 \n" )
		do_ObCall( "17202797684_002", cops_ct )

	elseif fromTn == "4" then
		freeswitch.consoleLog("INFO", ttl .. " 4 \n" )
		do_ObCall( "18014712100", cops_tt )

	elseif fromTn == "5" then
		freeswitch.consoleLog("INFO", ttl .. " 4 \n" )
		do_ObCall( "18014712100", cops_ct )

	else
		freeswitch.consoleLog("INFO", ttl .. " else - Why am I here? \n" )
	end
end






-- Use onNetTnList for both onNet TNs AND minutes to talk
local onNetTnList = {}

local onNetTnAlt = {}

-- Use onNetTnExt for extension Lists
local onNetTnExt = {}

onNetTnList['7202791225'] = 50
 onNetTnExt['7202791225'] = "0001,0002,0003"

onNetTnList['17202791225'] = 50
 onNetTnExt['17202791225'] = "0001,0002,0003"
 -- onNetTnExt['17202791225'] = "0001,0002,0003"

onNetTnList['17202797684'] = 50
 onNetTnExt['17202797684'] = "0001,0002,0003"

onNetTnList['17202797891'] = 50
 onNetTnExt['17202797891'] = "0001,0002,0003"

onNetTnList['17202799791'] = 1
 onNetTnExt['17202799791'] = "0001,0002,0003"

onNetTnList['17203813446'] = 50
 onNetTnExt['17202793446'] = "0001,0002,0003"

-- 17202797684_002

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

-- =====pArray=====
-- k=ext, v=0005|0006
-- k=odnis, v=8776448292  -- NOT USED
-- k=forwarding, v=0  -- NOT USED
-- k=request_id, v=bd2f7170d4185d5f5063aef65a989  -- NOT USED
-- k=timeToRing, v=30
-- k=callId, v=bd2f7170d4185d5f5063aef65a989
-- k=freeCall, v=false
-- k=route_response, v=1  -- NOT USED
-- k=tptn, v=7202791225
-- k=is_gogii_tptn, v=1
-- k=timeToForward, v=30
-- k=odnis_target, v=app
-- k=voiceMail, v=0
-- k=app2app, v=0
-- k=dstNum, v=7202791225
-- k=srcNum, v=2066041709
-- k=callSource, v=pstn
-- k=is911, v=0
-- k=deviceRegistered, v=1
-- k=token, v=
-- k=inbound, v=1
-- k=carrier, v=PSTN
-- k=minutes, v=5
-- k=enoughMinute, v=1
-- k=timeToVM, v=30
-- ----------------------------------------------------------------

function gogiiFakeApiLookup( fromTN, toTN, callID, callSource )

	appData['is_gogii_tptn'] = isGogiiTN( fromTN, toTN ) -- determines if at least on TN is Gogii owned

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


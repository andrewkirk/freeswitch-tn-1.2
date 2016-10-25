-- ==========================================================
-- SipStorm Global Variables 
-- ==========================================================

customerName ="enflick";
-- cops_ct = "usdalencopsct.layered.net";
cops_ct = "usdalencopsct.layered.net";
cops_tt = "usdalencopstt.layered.net";
-- cops_tt = "usdalencopstt.layered.net";

failCauses = "ORIGINATOR_CANCEL CALL_REJECTED NO_USER_RESPONSE LOSE_RACE USER_BUSY RECOVERY_ON_TIMER_EXPIRE "
-- failCauses = "UNALLOCATED_NUMBER ORIGINATOR_CANCEL CALL_REJECTED NO_USER_RESPONSE LOSE_RACE USER_BUSY RECOVERY_ON_TIMER_EXPIRE ALLOTTED_TIMEOUT"



-- =========================================================
-- logToDisk will log all fsLogXXX messages to disk
--  NOTE: This will drastically slow the system - us ONLY for debugging and testing .. NOT Production :) -->
--   Files are put in /etc/freeswitch/htdocs/uuidLogs/ with UUID.log name
-- Set to false for production
-- =========================================================
logToDisk = false;

-- =========================================================
-- If true, debug messages will go to FS console
--  AND optionally log file IF logToDisk is true
-- If false, log messages will not be logged to console or file
-- Set to false for production
-- =========================================================
debug=false;

logFileUrlBase = "http://127.0.0.1:8080/uuidLogs/"

defaultCallTimeOut = 14400;    -- 600 seconds 
answerTimeout = 30;    -- 45 seconds 
clientTryIterations = 15;
clientTimeBetweenTryIterations=2000;
defaultPrepaidTimerSeconds=60;   -- 60 seconds


baseOnInboundCallURL = "http://callrouter.touch.com/callback/layered/onInboundCall";
baseOnAnswerURL = "http://callrouter.touch.com/callback/layered/onAnswer";
basePrepaidTimerURL = "http://callrouter.touch.com/callback/layered/onPrepaidTimer";
baseOnCallEndURL = "http://callrouter.touch.com/callback/layered/onCallEnd";
toFromHeaderUserPart = 0;   -- 1 means full SIP header, 0 means just userpart
baseOnConfAddURL = "http://callrouter.touch.com/callback/layered/onConfAdd";
baseOnConfAnswerURL = "http://callrouter.touch.com/callback/layered/onConfAnswer";
serverOfRecord = "173.193.168.170:8080";
-- =========================================================
-- Where to find some static prompts and other items.
-- Should usually be set to the same place as this profile.lua 
-- =========================================================
customerBaseDirectory = "/etc/freeswitch/scripts/customerData/enflick/"

vmRecordDirectory = "/data/enflick/prod_vm_recordings/";

defaultProblemIvrAudioFile = customerBaseDirectory .. "goodbye.wav";
callNotAllowedPrompt = customerBaseDirectory .. "rejected.wav";
defaultVmPrompt = customerBaseDirectory .. "greeting.wav";


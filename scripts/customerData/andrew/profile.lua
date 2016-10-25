-- ==========================================================
-- SipStorm Global Variables 
-- ==========================================================

customerName ="andrew";

cops_ct = "50.23.224.101:6065";
cops_tt = "50.23.224.101:6075";
default_domain = "enflick.layered.net";

failCauses = "ORIGINATOR_CANCEL CALL_REJECTED NO_USER_RESPONSE LOSE_RACE USER_BUSY RECOVERY_ON_TIMER_EXPIRE "
-- failCauses = "UNALLOCATED_NUMBER ORIGINATOR_CANCEL CALL_REJECTED NO_USER_RESPONSE LOSE_RACE USER_BUSY RECOVERY_ON_TIMER_EXPIRE ALLOTTED_TIMEOUT"



-- =========================================================
-- logToDisk will log all fsLogXXX messages to disk
--  NOTE: This will drastically slow the system - us ONLY for debugging and testing .. NOT Production :) -->
--   Files are put in /etc/freeswitch/htdocs/uuidLogs/ with UUID.log name
-- Set to false for production
-- =========================================================
logToDisk = true;

-- =========================================================
-- If true, debug messages will go to FS console
--  AND optionally log file IF logToDisk is true
-- If false, log messages will not be logged to console or file
-- Set to false for production
-- =========================================================
debug=true;

logFileUrlBase = "http://173.193.187.36:8080/uuidLogs/"

defaultCallTimeOut = 600;    -- 600 seconds 
answerTimeout = 60;    -- 45 seconds 
clientTryIterations = 4;
clientTimeBetweenTryIterations=5000;
defaultPrepaidTimerSeconds=60;   -- 60 seconds

baseOnInboundCallURL = "http://50.23.224.98/andrew/onInboundCall";
baseOnAnswerURL = "http://50.23.224.98/andrew/onAnswer";
basePrepaidTimerURL = "http://50.23.224.98/andrew/onPrepaidTimer";
baseOnCallEndURL = "http://50.23.224.98/andrew/onCallEnd";

toFromHeaderUserPart = 0;   -- 1 means full SIP header, 0 means just userpart

-- =========================================================
-- Where to find some static prompts and other items.
-- Should usually be set to the same place as this profile.lua 
-- =========================================================
customerBaseDirectory = "/etc/freeswitch/scripts/customerData/andrew/"

vmRecordDirectory = "/data/enflick/vm_recordings/";

defaultProblemIvrAudioFile = customerBaseDirectory .. "goodbye.wav";
callNotAllowedPrompt = customerBaseDirectory .. "rejected.wav";
defaultVmPrompt = customerBaseDirectory .. "greeting.wav";


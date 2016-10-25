-- =========================================================================
--
--  Script to check NVP instance for answer and response
--
--
-- EXAMPLE: luarun NvpChecker.lua (email flag) (NVP IP and Port to test)
--      FROM CLI
--          luarun NvpChecker.lua 1 10.50.64.52:5060
--      FROM BASH
--          /etc/freeswitch/bin/fs_cli -x 'luarun NvpChecker.lua 1 10.50.64.52:5060'
--   NOTE: Email flag should be set to "1" if an email should be sent for ALL
--         tests.  Set Email flag to "0" if only Error messages should send emails
--
-- =========================================================================

api = freeswitch.API()

-- freeswitch.consoleLog("ERR", "** In NvpChecker.lua\n" )

-- ==========================================================
-- Initialize Variables
-- ==========================================================

local emailTo = "james.gledhill@sipstorm.com,andrew.kirk@sipstorm.com";
local emailFrom = "tpa-es-cos-232@sipstorm.com";
local emailSubjectPrefix = "Subject: NVP ";
local emailSubjectPostfix = "";
local emailBody = "";
local callHasErrors = false;
local origTimeOut = 20;
local audioFile = "/etc/freeswitch/sounds/music/8000/ponce-preludio-in-e-major.wav";
local timeA = 0;
local timeB = 0;
local timeC = 0;


-- ==========================================================
-- Test and/or Set Argv[1] -- emailAllTest
-- ==========================================================

local emailAllTest = argv[1];

if ( emailAllTest == nil ) then
    emailAllTest = 1;
end

emailAllTest = tonumber(emailAllTest);

-- ==========================================================
-- Test Argv[2] -- NvpIpAndPort
--   IF NOT SET send error email and do NOT call
--   IF SET then make call and continue with tests
-- ==========================================================
local NvpIpAndPort = argv[2];     -- 10.50.64.52:5060

if ( NvpIpAndPort == nil ) then
    freeswitch.consoleLog("ERR", "** NvpIpAndPort NOT SET *** EXITING  \n" )

    callHasErrors = true;
    emailBody = "* ERROR: NvpIpAndPort NOT SET *** EXITING  \n";

else

    -- ==========================================================
    -- This is the real Main Function
    -- ==========================================================

    emailSubjectPostfix = string.format( " - %s", NvpIpAndPort)

    -- local nvpSessionString = string.format(
        -- "{ignore_early_media=true,originate_timeout=%s,origination_caller_id_name=%s,ob_effective_caller_id_number=%s,"
            -- .. "}sofia/siptapi/%s@%s",
            -- origTimeOut, fsCallerName, fsCallerId, cellPhoneTN, NvpIpAndPort )

    local nvpSessionString = string.format(
        "{originate_timeout=%s,sip_invite_params=voicexml=http://10.50.64.119:10990/nvp-test/beepMe.vxml}sofia/siptapi/__sip-dialog@%s",
        origTimeOut, NvpIpAndPort)

    -- freeswitch.consoleLog("ERR", "** nvpSessionString = " .. nvpSessionString .. "\n" )

    timeA = api:getTime();

    local NvpSession = freeswitch.Session( nvpSessionString )

    if NvpSession:ready() == true then
        timeB = api:getTime();

        if ( (timeB - timeA) > 1000 ) then
            callHasErrors = true;
            emailBody = emailBody .. "* WARN: Call Setup To Long -- " .. tostring(timeB - timeA) .. "\n\n";
        end

        -- NvpSession:streamFile(audioFile);

        NvpSession:setVariable("my_tone", "0");
        NvpSession:setVariable("execute_on_tone_detect", "set my_tone=${strepoch()}");
        NvpSession:setVariable("tone_detect_hits", "1");
        NvpSession:execute("tone_detect", "my_tone 440 r +30000");
        NvpSession:streamFile(audioFile);

        -- NvpSession:execute("info");

        MyToneTime = tonumber(NvpSession:getVariable("my_tone"));
        AnswerTime = timeB - timeA;

        if ( MyToneTime == 0 ) then
            MyToneTimeDiff = 0
        else
            -- MyToneTimeDiff = MyToneTime - (timeB/1000)
            -- freeswitch.consoleLog("ERR", "** MyToneTime = " .. MyToneTime .. "\n" )
            -- freeswitch.consoleLog("ERR", "** timeB = " .. timeB .. "\n" )
            MyToneTimeDiff = math.floor((MyToneTime - (timeB/1000)) * 1000)
        end

        if ( MyToneTime == 0 ) then
            callHasErrors = true;
            emailBody = emailBody .. "* WARN: Tone not detected" ..  "\n\n";
        elseif ( MyToneTimeDiff > 3000 ) then    -- 3 seconds
            callHasErrors = true;
            emailBody = emailBody .. "* WARN: Tone Detected Delay Long (should be < 3000) = " .. tostring(MyToneTimeDiff) .. "\n\n";
        elseif ( AnswerTime > 1000 ) then    -- 3 seconds
            callHasErrors = true;
            emailBody = emailBody .. "* WARN: Answer Time To Long (should be < 1000) = " .. tostring(AnswerTime) .. "\n\n";
        end

        -- freeswitch.consoleLog("ERR", "***** MyToneTime = " .. tostring(MyToneTime) .. " MyToneTimeDiff = " .. tostring(MyToneTimeDiff) .. "\n");
    else
        callHasErrors = true;
        emailBody = emailBody ..
            "* ERROR: Call not connected\n    Hangup Cause = " .. NvpSession:hangupCause() .. "\n\n";
    end

    timeC = api:getTime();

    if ( (timeC - timeA ) > 5000 ) then
        callHasErrors = true;
        emailBody = emailBody .. "* WARN: Long Call -- " .. tostring(timeC - timeA) .. "\n\n";

    end

    emailBody = emailBody .. "* INFO: Call Setup Times\n    Answer Delay(ms): " .. tostring(AnswerTime)
            .. "\n    Tone Time from Answer(ms): " .. tostring(MyToneTimeDiff) .. "\n    Call Duration from Answer(ms): " .. tostring(timeC - timeA) .. "\n\n";

    freeswitch.consoleLog("INFO", "****** TONE DETECT  **** my_tone = " .. NvpSession:getVariable("my_tone") .. "\n" )
    -- freeswitch.consoleLog("ERR", "** Hangup Cause = " .. NvpSession:hangupCause() .. "\n")
    -- freeswitch.consoleLog("ERR", "** TimeA = " .. timeA .. "  TimeB = " .. timeB .. "   TimeC = " .. timeC .. "\n")
    freeswitch.consoleLog("INFO", "**** NVP Tester Tone Detect --> \n" .. emailBody )
    -- freeswitch.consoleLog("ERR", "** Leaving NvpChecker.lua !! \n")

end

-- ==========================================================
-- Email results
-- ==========================================================

if ( callHasErrors == true ) then
    emailSubject = emailSubjectPrefix .. "PROBLEM" .. emailSubjectPostfix;
    freeswitch.email(emailTo, emailFrom, emailSubject, emailBody);
elseif ( emailAllTest == 1 ) then
    emailSubject = emailSubjectPrefix .. "Report" .. emailSubjectPostfix;
    freeswitch.email(emailTo, emailFrom, emailSubject, emailBody);
end


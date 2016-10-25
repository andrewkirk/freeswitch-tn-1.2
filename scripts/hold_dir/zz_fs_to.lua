-- =========================================================================
--
--  FS TO Functionality
--     _____ ____    _____ ___
--    |  ___/ ___|  |_   _/ _ \
--    | |_  \___ \    | || | | |
--    |  _|  ___) |   | || |_| |
--    |_|   |____/    |_| \___/
--
-- EXAMPLE: luarun fs_to.lua <user_part>  -- User Part is phone number or name 
--      FROM CLI
--          luarun fs_to.lua 18014712099
--   NOTE: This will ...
--
-- =========================================================================

api = freeswitch.API()

-- NOTE:  "session" is the inbound session

freeswitch.consoleLog("ERR", "** In fs_to.lua\n" )

-- ==========================================================
-- Initialize Variables
-- ==========================================================

local ocr_co = "107.23.38.49:6060";
local ocr_ct = "107.23.38.49:6065";
local ocr_to = "107.23.38.49:6070";
local ocr_tt = "107.23.38.49:6075";

local origTimeOut = 45;    -- 45 seconds 

local ttl = "** fs_to.main - "
local toNumber = "NOT_SET";

local userPart = argv[1];

-- ==========================================================
-- Helper Functions 
-- ==========================================================

function do_co()   -- Client to Client

	ttl = "** fs_to.do_co - "

	freeswitch.consoleLog("INFO", ttl .. "Start \n" )

	toNumber = "18014712100";

	local coSessionString = string.format(
		"{originate_timeout=%s}sofia/fs_to_6070/%s@%s",
		origTimeOut, toNumber, ocr_co)

	freeswitch.consoleLog("INFO", ttl .. "coSessionString = " .. coSessionString .. "\n")

	local CO_Session = freeswitch.Session( coSessionString )

	freeswitch.consoleLog("INFO", ttl .. "End \n" )


end 


function do_ct()   -- Terminate to Client

	ttl = "** fs_to.do_ct - "

	freeswitch.consoleLog("INFO", ttl .. "Start \n" )

	toNumber = "18014712100_001";
	freeswitch.consoleLog("INFO", ttl .. toNumber .. "   \n" )

	local ctSessionString = string.format(
		"{originate_timeout=%s}sofia/fs_to_6070/%s@%s",
		origTimeOut, toNumber, ocr_ct)

	freeswitch.consoleLog("INFO", ttl .. "ctSessionString = " .. ctSessionString .. "\n")

	local CT_Session = freeswitch.Session( ctSessionString )

	freeswitch.consoleLog("INFO", ttl .. "End \n" )

end


function do_tt()   -- Terminate to PSTN

	ttl = "** fs_to.do_tt - "

	freeswitch.consoleLog("INFO", ttl .. "Start \n" )

	toNumber = "18014712100";

	ttSessionString = string.format(
		"{originate_timeout=%s}sofia/fs_to_6070/%s@%s",
		origTimeOut, toNumber, ocr_tt)

	freeswitch.consoleLog("INFO", ttl .. "ttSessionString = " .. ttSessionString .. "\n")

	local TT_Session = freeswitch.Session( ttSessionString )

	freeswitch.consoleLog("INFO", ttl .. "End \n" )

end



-- ==========================================================
-- Main
-- ==========================================================
ttl = "** fs_to.main - "


if (session ~= nil ) then
	-- ---------------------------------------------------
	-- This section is for being called via application
	-- ---------------------------------------------------

	freeswitch.consoleLog("INFO", ttl .. " session ~= nil \n" )
	local caller_id_number = session:getVariable("caller_id_number");
	local destination_number = session:getVariable("destination_number");
	local sip_from_user_stripped = session:getVariable("sip_from_user_stripped");

	local pNumbers = string.format(
		"\n -- caller_id_number = %s\n -- destination_number = %s\n -- sip_from_user_stripped = %s\n",
		caller_id_number, destination_number, sip_from_user_stripped)
	freeswitch.consoleLog("INFO", ttl .. pNumbers );

	if session:ready() then

		-- session:preAnswer();

		-- answer the call
		session:answer();

		-- sleep a second
		session:sleep(1000);

		-- play a file
		session:streamFile("/etc/freeswitch/sounds/en/us/callie/ivr/8000/ivr-stay_on_line_call_answered_momentarily.wav");

		-- hangup
		session:hangup();

	else
		freeswitch.consoleLog("WARN", ttl .. " Sessioin NOT Ready\n" );
	end
else
	-- ---------------------------------------------------
	-- This section is for testing via CLI
	-- ---------------------------------------------------

	freeswitch.consoleLog("INFO", ttl .. " session IS nil \n" )
	if ( userPart == "18015556666" ) then
		freeswitch.consoleLog("INFO", ttl .. " 18015556666 \n" )
		do_co()

	elseif userPart == "3" then
		freeswitch.consoleLog("INFO", ttl .. " 3 \n" )
		do_ct()

	elseif userPart == "4" then
		freeswitch.consoleLog("INFO", ttl .. " 4 \n" )
		do_tt()

	else
		freeswitch.consoleLog("INFO", ttl .. " else - Why am I here? \n" )
	end
end



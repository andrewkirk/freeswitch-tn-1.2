--          __     __    _                          _ _ 
--  ___  _ _\ \   / /__ (_) ___ ___ _ __ ___   __ _(_) |
-- / _ \| '_ \ \ / / _ \| |/ __/ _ \ '_ ` _ \ / _` | | |
--| (_) | | | \ V / (_) | | (_|  __/ | | | | | (_| | | |
-- \___/|_| |_|\_/ \___/|_|\___\___|_| |_| |_|\__,_|_|_|
--                                                      
--
-- wget --quiet -O - http://www.lemoda.net/games/figlet/figlet.cgi?text=onVoicemail
-- 
-- This LUA Code is done ONCE right after outbound call is made
-- 
-- SESSION BASED
--

api = freeswitch.API()

-- ****  uuid_simplify   *** DO THIS IF WE CAN

-- ==========================================================
-- Initialize Variables STATIC
-- ==========================================================

modName = "onVoicemail"

myUuid 			    = session:getVariable("uuid")
debugUuid           = myUuid;  -- This Leg is the primary leg for debug
logToDisk           = session:getVariable("fsd_logToDisk")
debug               = session:getVariable("fsd_debug")
answeredNumber 		= session:getVariable("destination_number");
toTN 	    		= session:getVariable("fsd_toTN");
fromTN 	    		= session:getVariable("fsd_fromTN");
baseOnAnswerURL 	= session:getVariable("fsd_on_answer_uri");
timerTime   		= session:getVariable("fsd_on_prepaid_timer_time")
vmPrompt    		= session:getVariable("fsd_vm_prompt")
useVM	    		= session:getVariable("fsd_use_vm")
defaultGreetingURI 	= session:getVariable("fsd_user_vm_greeting_uri")
vmRecordDirectory 	= session:getVariable("fsd_vmRecordDirectory")
vmRecordDirectory   = vmRecordDirectory ~= nil and vmRecordDirectory or "/data/voicemail/vm_recordings/";

customerName            = session:getVariable("fsd_customer_name")

filename = myUuid .."_" .. toTN .. "_" .. fromTN
recording_filename = string.format('%s%s.wav', vmRecordDirectory, filename)
recording_filename_short = string.format('%s.wav', filename)
recording_touchfile = string.format('%s%s.upload', vmRecordDirectory, filename)

-- ==========================================================
-- Shared Logging and Helper Functions 
--  Set modName, myUuid and debugUuid BEFORE this!!
-- ==========================================================
dofile("/etc/freeswitch/scripts/logAndHelper.lua")


function playGreetingAndRecord( )
	fsLogDebug( "******* playPrompt [ " .. tostring( prompt ) .. " ] ********" );
	fsLogDebug( "******* userGreetingURI = " .. tostring( userGreetingURI ) .. " ] ********" );
	fsLogDebug( "******* vmPrompt = " .. tostring( vmPrompt ) .. " ] ********" );

	if session:ready() then

		session:answer();
		session:sleep(1500);

		useUserGreeting = false;
		promptLocation = "";

		if vmPrompt ~= nil then
			promptLocation = api:execute("http_get", vmPrompt )
			
			-- Test for "-ERR" and handle that
			if ( isErr( promptLocation ) ) then
				useUserGreeting = false;
				fsLogDebug( "******* Switching to default VM prompt .. promptLocation = [ " .. promptLocation .. " ] ********" );
			else
				useUserGreeting = true;
			end
		end

		-- IF vmPrompt is not nil AND we downloaded it, then use that, otherwise play numbers
		if useUserGreeting then
			fsLogInfo( "** Using Greeting " .. promptLocation .. " **" );
			session:streamFile( promptLocation );
		else
			fsLogInfo( "** Using default greeting **" );
           	session:streamFile( "/etc/freeswitch/sounds/voicemail/textnow_vm.wav" );		
        end

		session:streamFile( "/etc/freeswitch/sounds/voicemail/beep.wav" );

		recordVM();

		session:streamFile( "/etc/freeswitch/sounds/voicemail/auth-thankyou.wav" );
	else
		fsLogError( "Session NOT Ready - Hanging up" );
		session:hangup();
	end

end

function playPrompt( prompt )
	fsLogInfo( "******* playPrompt [ " .. tostring( prompt ) .. " ] ********" );

	if session:ready() then

		-- session:preAnswer();
		session:answer();
		session:sleep(1500);
		session:streamFile( prompt );

	else
		fsLogError( " Session NOT Ready - Hanging up" );
		session:hangup();
	end

end


function onInputCBF(s, _type, obj, arg)
    local k, v = nil, nil
    local _debug = true
    if _debug then
        for k, v in pairs(obj) do
            -- printSessionFunctions(obj)
	    fsLogDebug( string.format('obj k-> %s v->%s\n', tostring(k), tostring(v)))
        end
        if _type == 'table' then
            for k, v in pairs(_type) do
	        fsLogDebug( string.format('_type k-> %s v->%s\n', tostring(k), tostring(v)))
            end
        end
	fsLogDebug( string.format('\n(%s == dtmf) and (obj.digit [%s])\n', _type, obj.digit))
    end
    if (_type == "dtmf") then
        return 'break'
    else
        return ''
    end
end

function recordVM()

	if session:ready() then
		fsLogInfo( "** Recording VM " .. recording_filename .. " **" )

		session:setInputCallback('onInputCBF', '');

		max_len_secs = 90
		silence_threshold = 20
		silence_secs = 5

		-- if test = 1 then there was a problem recording
		-- if test = 0 then recording is good
		-- syntax is session:recordFile(file_name, max_len_secs, silence_threshold, silence_secs)

		test = session:recordFile(recording_filename, max_len_secs, silence_threshold, silence_secs);

        fsLogInfo( "session:recordFile() = " .. test .. "" )

		if test >= 0 then
			session:setVariable("fsd_vmLocation", recording_filename_short )
	                freeswitch.consoleLog("err", "** VM Recorded " .. recording_filename_short .. " result " .. test .. " **success**\n");
                       --  freeswitch.consoleLog("err", "session:recordFile() = " .. test .. " **\n");
                        fsLogError( "** Voicemail file recording passed silence test **" )
            	else
		--  session:setVariable("fsd_vmLocation", "-ERR: There was a problem recording the VM file!" )
                --  session:setVariable("fsd_vmLocation", recording_filename_short )
	         session:setVariable("fsd_vmLocation", "nil" )
                    freeswitch.consoleLog("err", "** VM recording " .. recording_filename_short .. " result " .. test .. " **failed**\n");
                    -- freeswitch.consoleLog("err", "session:recordFile() = " .. test .. " **\n");
                     fsLogError( "** Voicemail file recording" .. recording_filename ..  " failed **" )
        end

		-- write/touch the '.upload file
		fsLogInfo( "** DOING touch " .. recording_touchfile .. " **" )
		local file = assert(io.open( recording_touchfile, "w"))  -- opening it creates a 0 byte file
		file:close();
	else
		fsLogDebug( "** Session not ready - Probably Hungup **" )
	end
end


-- ==========================================================
-- Main
-- ==========================================================

if true then    -- This is just so I can indent and have it make since to indent :) 

	fsLogInfo( "*******  START of onVoicemail.lua  *****" )

	if session:ready() then
        fsLogDebug("SESSION IS READY");

        fsLogDebug( api:executeString('uuid_dump ' .. myUuid )); 

        if ( tonumber(useVM) ~= 0 )  then
            fsLogDebug( "** Use VM != 0 ... so do it " .. useVM .. " **" )
            playGreetingAndRecord( vmPrompt )
            playPrompt( recording_filename )
        else
            fsLogDebug( "** Use VM == 0 ... NO VM experience here **" )
        end
    else
        fsLogDebug("SESSION IS --N-O-T--READY -- Probably Hungup Case");
    end

end

fsLogInfo( "*******  END of onVoicemail.lua  *****" )


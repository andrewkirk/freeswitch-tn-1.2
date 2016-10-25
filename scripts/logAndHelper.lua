-- ==========================================================
-- Logging
--   fsLog( logLevel, logString )
--   fsLogWarn( logString )
--   fsLogError( logString )
--   fsLogInfo( logString )
-- ==========================================================

-- NOTE:  modName should be set elsewhere
-- NOTE:  myUuid should be set elsewhere



function initLogging()
    logToDisk = (logToDisk ~= nil ) and logToDisk or false;
    debug = (debug ~= nil ) and debug or false;
    debugUuid = debugUuid ~= nil and debugUuid or myUuid;   -- use either uuid, but prefer LEG A (debugUuid)
    myUuid = (myUuid ~= nil ) and myUuid or "myUuid not set - set it at the top of the file that calls this function";
    modName = (modName ~= nil ) and modName or "modName not set - set it at the top of the lua file that calls this function";
end

initLogging();  -- Do it once when loaded and perhaps call it later after profile (re)load

function toBoolean(v)
    return (type(v) == "string" and v == "true") or (type(v) == "number" and v ~= 0) or (type(v) == "boolean" and v) or (type(v) == "string" and v == "yes")
end

-- ========================================================
-- fsLog prints to FS Console AND optionally to disk
-- ========================================================
function fsLog( logLevel, logString )


    if toBoolean(debug)  then  -- debug should be set in customer porfile.lua
        freeswitch.consoleLog(logLevel, 
            "\n\n** " ..  tostring( modName ) .. "[" .. 
            tostring( myUuid ) .. "]\n     " .. tostring( logString ) .. "\n");
        
        if toBoolean(logToDisk) then
            debugUuid = debugUuid ~= nil and debugUuid or myUuid;   -- use either uuid, but prefer LEG A (debugUuid)
            file = assert(io.open("/etc/freeswitch/htdocs/uuidLogs/" ..
                tostring(debugUuid) .. ".log", "a"));
            file:write("\n[" .. modName .. " (" .. logLevel .. ")] " .. 
                tostring( logString ) .. "\n");
            file:flush() 
            file:close() 
        end
    end

end

function fsLogWarn( logString )
	fsLog("WARNING", logString )
end

function fsLogError( logString )
	fsLog("ERR", logString )
end

function fsLogInfo( logString )
	fsLog("INFO", logString )
end

function fsLogDebug( logString )
	fsLog("DEBUG", logString )
end

-- ==========================================================
-- Play Error Messages
-- ==========================================================

function playCallNotAllowed()
	fsLogError( "******* playCallNotAllowed ********" );

	fsd_call_not_allowed_prompt = session:getVariable("fsd_call_not_allowed_prompt")

	if fsd_call_not_allowed_prompt ~= nil then
		promptLocation = api:execute("http_get", fsd_call_not_allowed_prompt )
		
		-- Test for "-ERR" and handle that
		if ( isErr( promptLocation ) ) then
			fsLogError( "******* Switching to default error prompt .. promptLocation = [ " .. promptLocation .. " ] ********" );
			promptLocation = callNotAllowedPrompt;   -- Customer default prompt
		end

		fsLogError( "******* promptLocation = [ " .. promptLocation .. " ] ********" );
		playPrompt( promptLocation )
	elseif callNotAllowedPrompt ~= nil then   -- callNotAllowedPrompt should come from customer profile
		fsLogError( "******* promptLocation = [ " .. callNotAllowedPrompt .. " ] ********" );
		playPrompt( callNotAllowedPrompt );
    else
		fsLogError( "******* NO PROMPT AVAILABLE  ********" );
		playPrompt( "/etc/freeswitch/scripts/prompts/ss" );
		-- session:answer();  -- Answer and wait to make bridging kill work
		-- session:sleep(1500);
	end

    session:hangup();

end

function playPrompt( prompt )
	fsLogInfo( "******* playPrompt [ " .. tostring( prompt ) .. " ] ********" );

	if session:ready() then

		-- session:preAnswer();
		session:answer();
		session:sleep(1500);
		session:streamFile( prompt );

	else
		fsLogError( " Sessioin NOT Ready - Hanging up" );
	end

end

-- ==========================================================
-- Helper Functions 
--   string:split( sep )
--   url_encode(str)
--   escape (s)
--   table_print(tbl)
-- ==========================================================

function string:split(sep)
        local sep, fields = sep or ",", {}
        local pattern = string.format("([^%s]+)", sep)
        self:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end

function url_encode(str)
	if (str) then
		str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^%w ])",
		function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub (str, " ", "+")
    else
        str = "NOT_SET"
	end
	return str	
end

function escape (s)
	s = string.gsub(s, "([&=+%c])", function (c)
		return string.format("%%%02X", string.byte(c))
	end)
	s = string.gsub(s, " ", "+")
	return s
end


function table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs (tt) do
      table.insert(sb, string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        table.insert(sb, string.format("%s = \n", tostring(key)));
        table.insert(sb, table_print (value, indent + 2, done))
        table.insert(sb, string.rep (" ", indent)) -- indent it
        -- table.insert(sb, "}\n");
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\"\n", tostring(value)))
      else
        table.insert(sb, string.format(
            "%s = \"%s\"\n", tostring (key), tostring(value)))
       end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

function to_string( tbl )
    if  "nil"       == type( tbl ) then
        return tostring(nil)
    elseif  "table" == type( tbl ) then
        return table_print(tbl)
    elseif  "string" == type( tbl ) then
        return tbl
    else
        return tostring(tbl)
    end
end

function isErr( strToCheck )

	local left4 = strToCheck:sub(1,4);
	
	fsLogDebug( "\n**** isErr left4 = **" .. left4 .. "**\n" );

	if ( left4 == "-ERR" ) then
		return true;
	elseif ( left4 == "ERRO" ) then
		return true;
	else
		return false;
	end
end


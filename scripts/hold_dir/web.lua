--
-- lua/api.lua
-- 
-- enable mod_xml_rpc and try http://127.0.0.1:8080/api/lua?lua/api.lua in your webbrowser
--
stream:write("Content-Type: text/html\n\n");
stream:write("<title>FreeSWITCH Command Portal</title>");
stream:write("<h2>FreeSWITCH Command Portal</h2>");
stream:write("<form method=post><input name=command size=40> ");
stream:write("<input type=submit value=\"Execute\">");
stream:write("</form><hr noshade size=1><br>");

command = env:getHeader("command");

if (command)  then
   api = freeswitch.API();
   reply = api:executeString(command);

   if (reply) then
      stream:write("<br><B>Command Result</b><br>" .. reply .. "\n");
   end

end

env:addHeader("cool", "true");
stream:write(env:serialize() .. "\n\n");

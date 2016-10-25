-- =========================================================================
--               ___       _                           _  ____      _ _ 
--    ___  _ __ |_ _|_ __ | |__   ___  _   _ _ __   __| |/ ___|__ _| | |
--   / _ \| '_ \ | || '_ \| '_ \ / _ \| | | | '_ \ / _` | |   / _` | | |
--  | (_) | | | || || | | | |_) | (_) | |_| | | | | (_| | |__| (_| | | |
--   \___/|_| |_|___|_| |_|_.__/ \___/ \__,_|_| |_|\__,_|\____\__,_|_|_|
--
-- Gets a call from FS, communicates with Customer backend and 
--  creates a dialer string for XML bridge
--
--   NOTE: This will ...
--
-- =========================================================================



function init()

    -- ==========================================================
    -- Initialize things
    --   Only do these (functions) IF session:ready()
    -- ==========================================================

    api = freeswitch.API()
    json = require('json')

    modName = "onInboundCall"   -- Needs to be global and set for log printing

    myUuid = session:getVariable("uuid")  -- Keep this at top so it can be use right away for logging! -- global
    debugUuid = myUuid;  -- This Leg is the primary leg for debug
    appData = {}  -- Needs to be global 

	-- Make sure fromTN does not have extension on it !! 
	-- This was for gogii to pull out evertthing BEFORE the 'x' 
	-- gogii numbers are 2334424243x0021 we only want before the 'x'

        fromTN = session:getVariable("sip_from_user");
        toTN = session:getVariable("destination_number");

    -- Strip leading plus "+" sign if there is one
    if ( tostring( toTN:sub(1,1 )) == "+" ) then
        toTN = toTN:sub(2);
    end

    if ( tostring( toTN:sub(1,3 )) == "011" ) then
        toTN = toTN:sub(4);
    end

    -- ==========================================================
    -- Shared Logging and Helper Functions 
    --  Set modName, myUuid and debugUuid BEFORE this!!
    -- ==========================================================
    dofile("/etc/freeswitch/scripts/logAndHelper.lua")

end

function setUpProfile()

    -- ########################################################################### 
    --  M U L T I - T E N A N T    S T U F F   :)
    -- ########################################################################### 
    -- This is where the Multi-tenant things go ...
    --   USE DIFFERENT PROFILES (lua code) for each tenant
    --   This loades lua code has critical variable needed for each tenant
    -- ==========================================================

    freeswitch.consoleLog("DEBUG", "\n*******  START of onInboundCall.lua  ==> toTN [" .. toTN .. "]  fromTN [" .. fromTN .. "]\n" )

    profileUsed ="No Profile"

    if fromTN == "7206278600x0001" or fromTN == "12706702320_old" or fromTN == "18014712099_old" then
        -- JBG Stuff
        dofile("/etc/freeswitch/scripts/customerData/jbg/profile.lua")
        profileUsed = "jbg"

    elseif  

        fromTN:match "12182032000.." or toTN:match "12182032000.." or
        fromTN:match "12674773333.." or toTN:match "12674773333.." or
        fromTN:match "12674863333.." or toTN:match "12674863333.." or
        fromTN:match "12676034444.." or toTN:match "12676034444.." or
        fromTN:match "12677972222.." or toTN:match "12677972222.." or
        fromTN:match "12678191111.." or toTN:match "12678191111.." or
        fromTN:match "12678192222.." or toTN:match "12678192222.." or
        fromTN:match "12678732222.." or toTN:match "12678732222.." or
        fromTN:match "13202073333.." or toTN:match "13202073333.." or
        fromTN:match "13236482222.." or toTN:match "13236482222.." or
        fromTN:match "14012173333.." or toTN:match "14012173333.." or
        fromTN:match "14013662222.." or toTN:match "14013662222.." or
        fromTN:match "14014263333.." or toTN:match "14014263333.." or
        fromTN:match "14015891111.." or toTN:match "14015891111.." or
        fromTN:match "14016463333.." or toTN:match "14016463333.." or
        fromTN:match "14016551111.." or toTN:match "14016551111.." or
        fromTN:match "14016552222.." or toTN:match "14016552222.." or
        fromTN:match "14017024444.." or toTN:match "14017024444.." or
        fromTN:match "14018593333.." or toTN:match "14018593333.." or
        fromTN:match "14132392222.." or toTN:match "14132392222.." or
        fromTN:match "14132514444.." or toTN:match "14132514444.." or
        fromTN:match "14843742222.." or toTN:match "14843742222.." or
        fromTN:match "14844161111.." or toTN:match "14844161111.." or
        fromTN:match "14844162222.." or toTN:match "14844162222.." or
        fromTN:match "14845312222.." or toTN:match "14845312222.." or
        fromTN:match "14845314444.." or toTN:match "14845314444.." or
        fromTN:match "14845323333.." or toTN:match "14845323333.." or
        fromTN:match "14845481111.." or toTN:match "14845481111.." or
        fromTN:match "15087432222.." or toTN:match "15087432222.." or
        fromTN:match "15416961111.." or toTN:match "15416961111.." or
        fromTN:match "17192127949.." or toTN:match "17192127949.." or
        fromTN:match "17192158190.." or toTN:match "17192158190.." or
        fromTN:match "17192158442.." or toTN:match "17192158442.." or
        fromTN:match "17192158525.." or toTN:match "17192158525.." or
        fromTN:match "17192208115.." or toTN:match "17192208115.." or
        fromTN:match "17192238259.." or toTN:match "17192238259.." or
        fromTN:match "17192238642.." or toTN:match "17192238642.." or
        fromTN:match "17192248286.." or toTN:match "17192248286.." or
        fromTN:match "17192458045.." or toTN:match "17192458045.." or
        fromTN:match "17192867536.." or toTN:match "17192867536.." or
        fromTN:match "17192948297.." or toTN:match "17192948297.." or
        fromTN:match "17193437105.." or toTN:match "17193437105.." or
        fromTN:match "17193437148.." or toTN:match "17193437148.." or
        fromTN:match "17193437508.." or toTN:match "17193437508.." or
        fromTN:match "17194178636.." or toTN:match "17194178636.." or
        fromTN:match "17194227535.." or toTN:match "17194227535.." or
        fromTN:match "17194453029.." or toTN:match "17194453029.." or
        fromTN:match "17194760605.." or toTN:match "17194760605.." or
        fromTN:match "17195307529.." or toTN:match "17195307529.." or
        fromTN:match "17195812578.." or toTN:match "17195812578.." or
        fromTN:match "17196027081.." or toTN:match "17196027081.." or
        fromTN:match "17196027268.." or toTN:match "17196027268.." or
        fromTN:match "17196028239.." or toTN:match "17196028239.." or
        fromTN:match "17196248375.." or toTN:match "17196248375.." or
        fromTN:match "17196248510.." or toTN:match "17196248510.." or
        fromTN:match "17196248561.." or toTN:match "17196248561.." or
        fromTN:match "17196628044.." or toTN:match "17196628044.." or
        fromTN:match "17196628485.." or toTN:match "17196628485.." or
        fromTN:match "17196628657.." or toTN:match "17196628657.." or
        fromTN:match "17196748605.." or toTN:match "17196748605.." or
        fromTN:match "17196967054.." or toTN:match "17196967054.." or
        fromTN:match "17196967367.." or toTN:match "17196967367.." or
        fromTN:match "17197518068.." or toTN:match "17197518068.." or
        fromTN:match "17197518655.." or toTN:match "17197518655.." or
        fromTN:match "17197528649.." or toTN:match "17197528649.." or
        fromTN:match "17197528679.." or toTN:match "17197528679.." or
        fromTN:match "17197528803.." or toTN:match "17197528803.." or
        fromTN:match "17197818164.." or toTN:match "17197818164.." or
        fromTN:match "17197828531.." or toTN:match "17197828531.." or
        fromTN:match "17198828320.." or toTN:match "17198828320.." or
        fromTN:match "17199288650.." or toTN:match "17199288650.." or
        fromTN:match "17199318092.." or toTN:match "17199318092.." or
        fromTN:match "17199318334.." or toTN:match "17199318334.." or
        fromTN:match "17199377580.." or toTN:match "17199377580.." or
        fromTN:match "17199388391.." or toTN:match "17199388391.." or
        fromTN:match "17199417657.." or toTN:match "17199417657.." or
        fromTN:match "17199668590.." or toTN:match "17199668590.." or
        fromTN:match "17199748219.." or toTN:match "17199748219.." or
        fromTN:match "17199828279.." or toTN:match "17199828279.." or
        fromTN:match "17199888548.." or toTN:match "17199888548.." or
        fromTN:match "17208004020.." or toTN:match "17208004020.." or
        fromTN:match "17208004021.." or toTN:match "17208004021.." or
        fromTN:match "17208004022.." or toTN:match "17208004022.." or
        fromTN:match "17208004023.." or toTN:match "17208004023.." or
        fromTN:match "17208004024.." or toTN:match "17208004024.." or
        fromTN:match "17208004025.." or toTN:match "17208004025.." or
        fromTN:match "17208004026.." or toTN:match "17208004026.." or
        fromTN:match "17208004027.." or toTN:match "17208004027.." or
        fromTN:match "17208004028.." or toTN:match "17208004028.." or
        fromTN:match "17208004029.." or toTN:match "17208004029.." or
        fromTN:match "17208004030.." or toTN:match "17208004030.." or
        fromTN:match "17208004031.." or toTN:match "17208004031.." or
        fromTN:match "17208004032.." or toTN:match "17208004032.." or
        fromTN:match "17208004033.." or toTN:match "17208004033.." or
        fromTN:match "17208004034.." or toTN:match "17208004034.." or
        fromTN:match "17208004035.." or toTN:match "17208004035.." or
        fromTN:match "17208004036.." or toTN:match "17208004036.." or
        fromTN:match "17208004037.." or toTN:match "17208004037.." or
        fromTN:match "17208004038.." or toTN:match "17208004038.." or
        fromTN:match "17208004039.." or toTN:match "17208004039.." or
        fromTN:match "17208004040.." or toTN:match "17208004040.." or
        fromTN:match "17208004041.." or toTN:match "17208004041.." or
        fromTN:match "17208004042.." or toTN:match "17208004042.." or
        fromTN:match "17208004043.." or toTN:match "17208004043.." or
        fromTN:match "17208004044.." or toTN:match "17208004044.." or
        fromTN:match "17326954444.." or toTN:match "17326954444.." or
        fromTN:match "17327863333.." or toTN:match "17327863333.." or
        fromTN:match "17329082222.." or toTN:match "17329082222.." or
        fromTN:match "17818193333.." or toTN:match "17818193333.." or
        fromTN:match "19087771111.." or toTN:match "19087771111.." or
        fromTN:match "19089863333.." or toTN:match "19089863333.." or
        fromTN:match "19145863333.." or toTN:match "19145863333.." or
        fromTN:match "19735676000.." or toTN:match "19735676000.." or
        fromTN:match "19782720998.." or toTN:match "19782720998.." or
        fromTN:match "19782723333.." or toTN:match "19782723333.." or
        fromTN:match "19783610999.." or toTN:match "19783610999.." or
        fromTN:match "19783933333.." or toTN:match "19783933333.." or
        fromTN:match "19784000099.." or toTN:match "19784000099.." or
        fromTN:match "19787062999.." or toTN:match "19787062999.." or
        fromTN:match "19787574444.." or toTN:match "19787574444.." or
        fromTN:match "19787924444.." or toTN:match "19787924444.." or
        fromTN:match "19788062999.." or toTN:match "19788062999.." or
        fromTN:match "19788063333.." or toTN:match "19788063333.." or
        fromTN:match "12263152978.." or toTN:match "12263152978.." or
        fromTN:match "12263173173.." or toTN:match "12263173173.." or
        fromTN:match "12263173272.." or toTN:match "12263173272.." or
        fromTN:match "12263173335.." or toTN:match "12263173335.." or
        fromTN:match "12266460174.." or toTN:match "12266460174.." or
        fromTN:match "16477935748.." or toTN:match "16477935748.." or
        fromTN:match "16477940277.." or toTN:match "16477940277.." or
        fromTN:match "16477942461.." or toTN:match "16477942461.." or
        fromTN:match "16477946031.." or toTN:match "16477946031.." or
        fromTN:match "16477946764.." or toTN:match "16477946764.." or

-- Craigs old numbers
        fromTN:match "16479540353.." or toTN:match "16479540353.." or
        fromTN:match "16479540354.." or toTN:match "16479540354.." or
        fromTN:match "16479540355.." or toTN:match "16479540355.." then



        -- Enflick test environment stuff
        dofile("/etc/freeswitch/scripts/customerData/enflick_test/profile.lua")
        profileUsed = "enflick_test"

    elseif
        fromTN:match "12263152673.." or toTN:match "12263152673.." or
        fromTN:match "12263152673.." or toTN:match "12263152673.." or
        fromTN:match "12263162555.." or toTN:match "12263162555.." or
        fromTN:match "12263162686.." or toTN:match "12263162686.." or
        fromTN:match "12263173147.." or toTN:match "12263173147.." or
        fromTN:match "12263173478.." or toTN:match "12263173478.." or
        fromTN:match "14259392222.." or toTN:match "14259392222.." or
        fromTN:match "15097381111.." or toTN:match "15097381111.." or
        fromTN:match "16043435067.." or toTN:match "16043435067.." or
        fromTN:match "16043435229.." or toTN:match "16043435229.." or
        fromTN:match "16043435515.." or toTN:match "16043435515.." or
        fromTN:match "16043435983.." or toTN:match "16043435983.." or
        fromTN:match "16043436310.." or toTN:match "16043436310.." or
        fromTN:match "16043436349.." or toTN:match "16043436349.." or
        fromTN:match "16043436524.." or toTN:match "16043436524.." or
        fromTN:match "16043436589.." or toTN:match "16043436589.." or
        fromTN:match "16043436827.." or toTN:match "16043436827.." or
        fromTN:match "16043438203.." or toTN:match "16043438203.." or
        fromTN:match "16043438222.." or toTN:match "16043438222.." or
        fromTN:match "16043438653.." or toTN:match "16043438653.." or
        fromTN:match "16043438936.." or toTN:match "16043438936.." or
        fromTN:match "16043439434.." or toTN:match "16043439434.." or
        fromTN:match "16043439642.." or toTN:match "16043439642.." or
        fromTN:match "16046740064.." or toTN:match "16046740064.." or
        fromTN:match "16046740268.." or toTN:match "16046740268.." or
        fromTN:match "16046740270.." or toTN:match "16046740270.." or
        fromTN:match "16046740840.." or toTN:match "16046740840.." or
        fromTN:match "16046740947.." or toTN:match "16046740947.." or
        fromTN:match "16046741400.." or toTN:match "16046741400.." or
        fromTN:match "16046741584.." or toTN:match "16046741584.." or
        fromTN:match "16046741591.." or toTN:match "16046741591.." or
        fromTN:match "16046741667.." or toTN:match "16046741667.." or
        fromTN:match "16046741795.." or toTN:match "16046741795.." or
        fromTN:match "16046741954.." or toTN:match "16046741954.." or
        fromTN:match "16046742161.." or toTN:match "16046742161.." or
        fromTN:match "16046742410.." or toTN:match "16046742410.." or
        fromTN:match "16046742438.." or toTN:match "16046742438.." or
        fromTN:match "16046742542.." or toTN:match "16046742542.." or
        fromTN:match "16046742574.." or toTN:match "16046742574.." or
        fromTN:match "16046742887.." or toTN:match "16046742887.." or
        fromTN:match "16046742953.." or toTN:match "16046742953.." or
        fromTN:match "16046743919.." or toTN:match "16046743919.." or
        fromTN:match "16046744100.." or toTN:match "16046744100.." or
        fromTN:match "16046744939.." or toTN:match "16046744939.." or
        fromTN:match "16046745014.." or toTN:match "16046745014.." or
        fromTN:match "16046745630.." or toTN:match "16046745630.." or
        fromTN:match "16046745646.." or toTN:match "16046745646.." or
        fromTN:match "16046746290.." or toTN:match "16046746290.." or
        fromTN:match "16046746314.." or toTN:match "16046746314.." or
        fromTN:match "16046746425.." or toTN:match "16046746425.." or
        fromTN:match "16046747066.." or toTN:match "16046747066.." or
        fromTN:match "16046747673.." or toTN:match "16046747673.." or
        fromTN:match "16046748131.." or toTN:match "16046748131.." or
        fromTN:match "16046748189.." or toTN:match "16046748189.." or
        fromTN:match "16046748400.." or toTN:match "16046748400.." or
        fromTN:match "16046748565.." or toTN:match "16046748565.." or
        fromTN:match "16046749365.." or toTN:match "16046749365.." or
        fromTN:match "16046749670.." or toTN:match "16046749670.." or
        fromTN:match "16477956016.." or toTN:match "16477956016.." or
        fromTN:match "16477388051.." or toTN:match "16477388051.." or
        fromTN:match "16477932932.." or toTN:match "16477932932.." or
        fromTN:match "16477933580.." or toTN:match "16477933580.." or
        fromTN:match "16477954895.." or toTN:match "16477954895.." or
        fromTN:match "17208004045.." or toTN:match "17208004045.." or
        fromTN:match "17208004046.." or toTN:match "17208004046.." or
        fromTN:match "17208004047.." or toTN:match "17208004047.." or
        fromTN:match "17208004048.." or toTN:match "17208004048.." or
        fromTN:match "17208004049.." or toTN:match "17208004049.." or
        fromTN:match "17208004050.." or toTN:match "17208004050.." or
        fromTN:match "17208004051.." or toTN:match "17208004051.." or
        fromTN:match "17208004052.." or toTN:match "17208004052.." or
        fromTN:match "17208004053.." or toTN:match "17208004053.." or
        fromTN:match "17208004054.." or toTN:match "17208004054.." or
        fromTN:match "17208004055.." or toTN:match "17208004055.." or
        fromTN:match "17208004056.." or toTN:match "17208004056.." or
        fromTN:match "17208004057.." or toTN:match "17208004057.." or
        fromTN:match "17208004058.." or toTN:match "17208004058.." or
        fromTN:match "17208004059.." or toTN:match "17208004059.." or
        fromTN:match "17208004060.." or toTN:match "17208004060.." or
        fromTN:match "17208004061.." or toTN:match "17208004061.." or
        fromTN:match "17208004062.." or toTN:match "17208004062.." or
        fromTN:match "17208004063.." or toTN:match "17208004063.." or
        fromTN:match "17208004064.." or toTN:match "17208004064.." or
        fromTN:match "17208004065.." or toTN:match "17208004065.." or
        fromTN:match "17208004066.." or toTN:match "17208004066.." or
        fromTN:match "17208004067.." or toTN:match "17208004067.." or
        fromTN:match "17208004068.." or toTN:match "17208004068.." or
        fromTN:match "17208004069.." or toTN:match "17208004069.." or
        fromTN:match "17819512345.." or toTN:match "17819512345.." or
        fromTN:match "19732912222.." or toTN:match "19732912222.." or
        fromTN:match "19782160994.." or toTN:match "19782160994.." or
        fromTN:match "19782163998.." or toTN:match "19782163998.." or
        fromTN:match "19783150997.." or toTN:match "19783150997.." or
        fromTN:match "19783470995.." or toTN:match "19783470995.." or
        fromTN:match "19783612997.." or toTN:match "19783612997.." or
        fromTN:match "19783640995.." or toTN:match "19783640995.." or
        fromTN:match "19785150996.." or toTN:match "19785150996.." or
        fromTN:match "19785932997.." or toTN:match "19785932997.." or
        fromTN:match "19787062997.." or toTN:match "19787062997.." or
        fromTN:match "19787913333.." or toTN:match "19787913333.." or
        fromTN:match "19788202996.." or toTN:match "19788202996.." then

        -- Enflick staging environment stuff
        dofile("/etc/freeswitch/scripts/customerData/enflick_stage/profile.lua")
        profileUsed = "enflick_stage"

    elseif toTN == "18135270613" or fromTN == "18135270613" or fromTN == "18135279999" or 
        toTN == "12147235506" or fromTN == "12147235506" or 
        toTN == "19252900097" or fromTN == "19252900097" or
        toTN == "441133201799" or fromTN == "441133201799" or 
        toTN == "19195785577" or fromTN == "19195785577" then
            -- Andrew2Asterisk stuff
        dofile("/etc/freeswitch/scripts/customerData/andrew2asterisk/profile.lua")
        profileUsed = "Andrew2Asterisk"

    else
        dofile("/etc/freeswitch/scripts/customerData/enflick/profile.lua")
        profileUsed = "enflick - default"
        -- playCallNotAllowed()
    end





    initLogging();  -- reset logging details for this profile

    fsLogInfo( "\n*******  START of onInboundCall.lua  ==> profile [" .. profileUsed .. "] toTN [" .. toTN .. "]  fromTN [" .. fromTN .. "]\n" )

    -- ==========================================================
    -- Make SURE customer specific data is set up
    --  From imported profile.lua ...
    -- ==========================================================


    defaultCallTimeOut = defaultCallTimeOut ~= nill and defaultCallTimeOut or 600;
    answerTimeout = answerTimeout ~= nil and answerTimeout or 60;
        -- AK pstnAnswerTimeout used for pstn termination timeout
    pstnAnswerTimeout = pstnAnswerTimeout ~= nil and pstnAnswerTimeout or 90;
    clientTryIterations = clientTryIterations ~= nill and clientTryIterations or 6;
    clientTimeBetweenTryIterations = clientTimeBetweenTryIterations ~= nil and clientTimeBetweenTryIterations or 5000;
    defaultPrepaidTimerSeconds = defaultPrepaidTimerSeconds ~= nill and defaultPrepaidTimerSeconds or 60;
    defaultPrepaidTimerSeconds = defaultPrepaidTimerSeconds >= 5 and defaultPrepaidTimerSeconds or 5;
    toFromHeaderUserPart = toFromHeaderUserPart ~= nil and toFromHeaderUserPart or 0;
    customerName = customerName ~= nil and customerName or "No_Customer_Names_Set";
    vmRecordDirectory = vmRecordDirectory ~= nil and vmRecordDirectory or "/data/voicemail/vm_recordings/";

    if (
        ( baseOnInboundCallURL == nil ) or 
        ( baseOnAnswerURL == nil ) or
        ( basePrepaidTimerURL == nil ) or
        ( baseOnCallEndURL == nil ) or
        ( defaultProblemIvrAudioFile == nil ) or
        ( callNotAllowedPrompt == nil ) or
        ( defaultVmPrompt == nil )
        ) then

        fsLogError( "Something in the customer profile.lua file was not set properly .. please check and try again!");
        playCallNotAllowed();

    end

end
-- ==========================================================
-- Build Dialer Strings
-- ==========================================================


function createComboObString( )   -- Terminate to Client/App
	appData['obClientArray'] = {}
    local clientString

    if ( appData.to_addresses ~= nil ) then

        for i, to_uri in ipairs( appData.to_addresses ) do

            if to_uri:find("@") ~= nil then    -- Client Routing
                clientString = string.format(
                    "{origination_uuid=%s_%i,sip_h_X-Route-Helper=%s" .. 
                    ",fsd_call_term_type=client,originate_retries=%i,originate_retry_sleep_ms=%i" ..
                    ",leg_timeout=%i" ..
                    ",sip_invite_to_uri=<sip:%s>}" ..
                    "sofia/outbound_5060/%s@%s",
                    myUuid, i, to_uri:sub(to_uri:find("@") +1 ),
                    -- clientTryIterations & clientTimeBetweenTryIterations come from customer profile "dofile"
                    tonumber( clientTryIterations ), tonumber( clientTimeBetweenTryIterations ), 
                    tonumber( answerTimeout ),
                    tostring( to_uri ),
        
                    to_uri:sub(1, to_uri:find("@")-1), cops_ct )

            elseif to_uri:find("%%") ~= nil then -- Special PSTN Carrier Routing 2 %% because of special character escape

                clientString = string.format(
                    "{origination_uuid=%s_%i,sip_h_X-Route-Helper=%s" .. 
                    ",leg_timeout=%i" ..
                    ",fsd_call_term_type=%s}" ..
                    "sofia/outbound_5060/%s@%s",
                    myUuid, i, to_uri:sub( to_uri:find("%%") +1 ),
                    tonumber( pstnAnswerTimeout ),
                    to_uri:sub( to_uri:find("%%") +1 ),
                    to_uri:sub(1, to_uri:find("%%")-1), cops_tt )

            else  -- Standard PSTN
                clientString = string.format(
                    "{origination_uuid=%s_%i,sip_h_X-Route-Helper=%s" .. 
                    ",leg_timeout=%i" ..
                    ",fsd_call_term_type=pstn}" ..
                    "sofia/outbound_5060/%s@%s",
                    myUuid, i, "pstn",
                    tonumber( pstnAnswerTimeout ),
                    to_uri, cops_tt )

            end

            table.insert(appData['obClientArray'], clientString )
        end

    else
        fsLogError( "No to_addresses for createComboObString( ) ... Playing prompt and exit")
        playCallNotAllowed()

    end

	local obSessionString = string.format(
		"<execute_on_answer='lua /etc/freeswitch/scripts/onAnswer.lua'" ..
        ",originate_timeout=%i" ..
		",set_zombie_exec,session_in_hangup_hook=true,api_hangup_hook='lua /etc/freeswitch/scripts/onHupTest.lua'" ..
		",fail_on_single_reject='%s',ignore_early_media=true" ..

		-- ",originate_retries=%i,originate_retry_sleep_ms=%i" ..

		",caller_id_type=pid,origination_caller_id_number=%s" ..
		",fsd_toTN=%s,fsd_fromTN=%s" ..
		",fsd_leg=ob,fsd_use_vm=%i,fsd_user_vm_greeting_uri='%s'" ..
		",fsd_on_answer_uri='%s',fsd_on_call_end_uri='%s'" ..
		",fsd_on_conf_add_uri='%s',fsd_on_conf_answer_uri='%s'" ..
                ",fsd_on_prepaid_timer_time=%i,fsd_on_prepaid_timer_uri='%s'" ..
		",fsd_call_orig_type=%s" ..
		",fsd_call_timeout=%i,fsd_to_address=%s" ..
		",fsd_uuid=%s,fsd_uuid_bleg_to_kill=%s" ..
		",fsd_logToDisk=%s,fsd_debug=%s" ..
		",fsd_customer_name=%s" ..
                ",fsd_default_domain=%s" ..
                ",fsd_cops_tt=%s,fsd_cops_ct=%s" ..
		">%s",
        tonumber( answerTimeout ),
		tostring( failCauses ), 

        -- clientTryIterations & clientTimeBetweenTryIterations come from customer profile "dofile"
		-- tonumber( clientTryIterations ), tonumber( clientTimeBetweenTryIterations ), 
        
		tostring( appData.caller_id ), 
		tostring( toTN ), tostring( fromTN ), 
		tonumber( appData.use_vm ), tostring( appData.user_vm_greeting_uri ),
		tostring( appData.on_answer_uri ), tostring( appData.on_call_end_uri ),
                tostring( appData.on_conf_add_uri ), tostring( appData.on_conf_answer_uri ),
		tonumber( appData.on_prepaid_timer_time ), tostring( appData.on_prepaid_timer_uri ),
		tostring( appData.call_orig_type ), 
		tonumber( appData.call_timeout ), tostring( appData.to_address ),
		tostring( myUuid ), tostring( myUuid ), 
		tostring( appData.logToDisk ), tostring( appData.debug ),
		tostring( customerName ),
                tostring( default_domain ),
                tostring( cops_tt ), tostring( cops_ct ),
        table.concat( appData['obClientArray'], ":_:" ) 

	);

		-- obSessionString = string.format("%s%s", 
			-- obSessionString,  table.concat( appData['obClientArray'], ":_:" ) )

	session:setVariable("obString", obSessionString )

	fsLogInfo( "DialString == " .. obSessionString )

end

-- ==========================================================
-- Get Profile Data for customer
--  Right now this is base on TN, but later will be a different SIP Header!!!
-- ==========================================================
-- ==========================================================
-- Main
-- ==========================================================

-- if (session ~= nil ) then

if session:ready() then

    init()

    setUpProfile()

	-- -----------------------------------------------------------------------
	-- We strip the FS profile names to get either 'softphone' or 'pstn'
	--   callSource should be softphone_xxxx or pstn_xxxx - strip the "_xxxx"
	-- -----------------------------------------------------------------------

	callSource = session:getVariable("sofia_profile_name");
	-- callSource should be softphone_xxxx or pstn_xxxx - strip the "_xxxx"
	callSource = string.match(callSource, "(.-)_") and string.match(callSource, "(.-)_") or callSource

	-- -----------------------------------------------------
	-- Set the Hangup Hook API to clean up ...
	--   We do it here to only get the answered/bridged channel
	--   Use session_in_hangup_hook to keep variables around for hangup processing
	-- -----------------------------------------------------

	session:setVariable( "accountcode",  "fsDialer" )  -- used for CDR
	session:setVariable( "api_hangup_hook",  "lua /etc/freeswitch/scripts/onCallEnd.lua" )  -- Set lua code to call at hangup
	session:setVariable( "session_in_hangup_hook", "true" )  -- so we can get details in lua after hangup
	session:execute("set_zombie_exec")  -- so we can get details in lua after hangup

    -- session:setVariable("fsd_uuid", myUuid )
	session:setVariable( "call_timeout", answerTimeout )
    session:setVariable( "fsd_toTN", toTN )
    session:setVariable( "fsd_fromTN", fromTN )
    session:setVariable( "fsd_leg", "ib" )
    session:setVariable( "fsd_call_orig_type", callSource )
    session:setVariable( "fsd_customer_name", customerName )
    session:setVariable( "fsd_vmRecordDirectory", vmRecordDirectory )
    session:setVariable( "fsd_cops_ct", cops_ct )
    session:setVariable( "fsd_cops_tt", cops_tt )
    session:setVariable( "fsd_default_domain", default_domain )
    session:setVariable( "fsd_toTN", toTN );
    session:setVariable( "fsd_fromTN", fromTN );
    


    if logFileUrlBase ~= nil then
        session:setVariable( "fsd_logFileUrl", tostring( logFileUrlBase ) .. myUuid .. ".log" )
    end


	-- -----------------------------------------------------------------------
	-- Send Data to Server and get JSON response 
	-- -----------------------------------------------------------------------
	local postData = "to=" .. url_encode( "+" .. toTN )
		.. "&from=" .. url_encode( fromTN ) 
		.. "&uuid=" .. url_encode( myUuid ) 
		.. "&source=" .. url_encode( callSource )
		.. "&origSipToUri=" .. url_encode( session:getVariable("sip_to_uri") )
		.. "&origSipFromUri=" .. url_encode( session:getVariable("sip_from_uri") )
                .. "&dtmfcollect=" .. url_encode( session:getVariable("dtmfcollect") )
                .. "&serverOfRecord=" .. url_encode( tostring( serverOfRecord) )
		.. "&origSipCallId=" .. url_encode( session:getVariable("sip_call_id") )
		.. "&customer=" .. url_encode( customerName )

	fsLogWarn( string.format("\n----------------------\n %s post %s\n------------------------", 
        baseOnInboundCallURL, postData ))

        session:execute("curl", baseOnInboundCallURL .. " post " .. url_encode(postData) )

	curl_response_code = session:getVariable("curl_response_code")
	curl_response      = session:getVariable("curl_response_data")

	fsLogWarn( " curl_response_code = " .. curl_response_code )
	fsLogWarn( " curl_response = " .. curl_response )


    if curl_response_code == "200" then
        appData = json.decode( curl_response )
    end

    if curl_response_code ~= "200" then

        -- -----------------------------------------------------------------------
        -- If curl response code is not 200, then play "bad" prompt and hangup
        -- -----------------------------------------------------------------------

        fsLogError( string.format("*******  curl_response_code ERROR: %s  Message: %s ********",
            tostring( curl_response_code), tostring(curl_response) ))
        playCallNotAllowed()
        -- session:hangup();

    elseif appData.error_code ~= nil then

        -- -----------------------------------------------------------------------
        -- If Error_code is returned, then play "bad" prompt and hangup
        -- -----------------------------------------------------------------------

        fsLogError( string.format("*******  appData.error_code ERROR: %s  Message: %s ********",
            tostring( appData.error_code), tostring(appData.message) ))
        playCallNotAllowed()
        -- session:hangup();

    else

        fsLogDebug( string.format("\n----------------  curl_response_code: %s  \nMessage:\n %s \n---------\n",
            tostring( curl_response_code), tostring(curl_response) ))

        fsLogDebug( "\n----- appData Before Processing ------\n" ..  to_string( appData ) .. "\n--------------------------");

        -- -----------------------------------------------------------------------
        -- Check and save returned JSON data
        -- -----------------------------------------------------------------------

        appData.call_orig_type = callSource

        -- -----------------------------------------------------------------------
        -- Required Data
        -- -----------------------------------------------------------------------

        if appData.allow_call ~= nil then
            session:setVariable("fsd_allow_call", 	appData.allow_call )
        else
            fsLogError( "*******  Manditory JSON value allow_call not returned *****" )
            playCallNotAllowed()
        end

        if appData.billing_uri ~= nil then
            session:setVariable("fsd_from_address", 	appData.billing_uri )
        elseif appData.from_address ~= nil then
            session:setVariable("fsd_from_address", 	appData.from_address )
        else
            fsLogError( "*******  Manditory JSON value billing_uri or from_address not returned *****" )
            playCallNotAllowed()
        end

        if appData.to_address ~= nil then
            session:setVariable("fsd_to_address", 	appData.to_address )
        elseif appData.to_addresses ~= nil then
            session:setVariable("fsd_to_address", 	"multiple" )
        else
            fsLogError( "*******  Manditory JSON value to_address not returned *****" )
            playCallNotAllowed()
        end

        -- -----------------------------------------------------------------------
        -- Optional Data - Check or set defaults
        -- -----------------------------------------------------------------------

        if appData.user_vm_greeting_prompt ~= nil then
            session:setVariable("fsd_vm_prompt", 	appData.user_vm_greeting_prompt )
        else
            -- IF no prompt set, then leave null
            -- session:setVariable("fsd_vm_prompt", 	defaultVmPrompt )
            -- appData.user_vm_greeting_prompt = defaultVmPrompt    -- from Default file 
        end

        if appData.logToDisk ~= nil then
            -- IF debug is set from RESTful API, over-write profile value
            session:setVariable("fsd_logToDisk", 	appData.logToDisk )
            logToDisk = appData.logToDisk;
        else
            session:setVariable("fsd_logToDisk", 	tostring( logToDisk ))
            appData.logToDisk = logToDisk;
        end

        if appData.answer_timeout ~= nil then
            -- IF answerTimeout is set from RESTful API, over-write profile value
            session:setVariable("fsd_answer_timeout",    appData.answer_timeout )
            answerTimeout = appData.answer_timeout;
        else
            session:setVariable("fs_answer_timeout",    tostring( answer_timeout ))
            appData.answer_timeout = answerTimeout;
        end

        if appData.pstn_answer_timeout ~= nil then
            -- IF pstnAnswerTimeout is set from RESTful API, over-write profile value
           session:setVariable("fsd_pstn_answer_timeout",    appData.pstn_answer_timeout )
           pstnAnswerTimeout = appData.pstn_answer_timeout;
        else
           session:setVariable("fsd_pstn_answer_timeout",    tostring( pstn_answer_timeout ))
           appData.pstn_answer_timeout = pstnAnswerTimeout;
        end

        if appData.debug ~= nil then
            -- IF debug is set from RESTful API, over-write profile value
            session:setVariable("fsd_debug", 	appData.debug )
            debug = appData.debug;
        else
            session:setVariable("fsd_debug", 	tostring(debug ))
            appData.debug = debug;
        end

        if appData.caller_id ~= nil then
            session:setVariable("fsd_caller_id", 	appData.caller_id )
        else
            session:setVariable("fsd_caller_id",        appData.from_address )
            appData.caller_id = appData.from_address
        end

        if appData.call_timeout ~= nil then
            session:setVariable("fsd_call_timeout", 	appData.call_timeout )
        else
            session:setVariable("fsd_call_timeout", 	defaultCallTimeOut )
            appData.call_timeout = defaultCallTimeOut
        end

        if appData.use_vm ~= nil then
            session:setVariable("fsd_use_vm", 	appData.use_vm )
        else
            -- default is 0 (zero) == no voicemail
            session:setVariable("fsd_use_vm", 	0 )
            appData.use_vm = 0
        end

        if appData.user_vm_greeting_uri ~= nil then
            session:setVariable("fsd_user_vm_greeting_uri", 	appData.user_vm_greeting_uri )
        else
            session:setVariable("fsd_user_vm_greeting_uri", 	defaultVmPrompt )
            appData.user_vm_greeting_uri = defaultVmPrompt 
        end

        if appData.call_not_allowed_prompt ~= nil then
            session:setVariable("fsd_call_not_allowed_prompt", 	appData.call_not_allowed_prompt )
        else
            session:setVariable("fsd_call_not_allowed_prompt", 	callNotAllowedPrompt )
            appData.call_not_allowed_prompt = callNotAllowedPrompt
        end

        if appData.on_answer_uri ~= nil then
            session:setVariable("fsd_on_answer_uri", 	appData.on_answer_uri )
        else
            session:setVariable("fsd_on_answer_uri", 	baseOnAnswerURL )
            appData.on_answer_uri = baseOnAnswerURL
        end

        if appData.on_prepaid_timer_uri ~= nil then
            session:setVariable("fsd_on_prepaid_timer_uri", 	appData.on_prepaid_timer_uri )
        else
            session:setVariable("fsd_on_prepaid_timer_uri", 	basePrepaidTimerURL )
            appData.on_prepaid_timer_uri = basePrepaidTimerURL
        end

        if appData.on_prepaid_timer_time ~= nil then
            if appData.on_prepaid_timer_time == 0  then
                -- leave it at 0
            else
                appData.on_prepaid_timer_time = appData.on_prepaid_timer_time >= 5 and appData.on_prepaid_timer_time or 5;
            end 
            session:setVariable("fsd_on_prepaid_timer_time", 	appData.on_prepaid_timer_time )
        else
            session:setVariable("fsd_on_prepaid_timer_time", 	defaultPrepaidTimerSeconds )
            appData.on_prepaid_timer_time = defaultPrepaidTimerSeconds
        end

        if appData.on_call_end_uri ~= nil then
            session:setVariable("fsd_on_call_end_uri", 	appData.on_call_end_uri )
        else
            session:setVariable("fsd_on_call_end_uri", 	baseOnCallEndURL )
            appData.on_call_end_uri = baseOnCallEndURL
        end

        if appData.on_conf_add_uri  ~= nil then
            session:setVariable("fsd_on_conf_add_uri",  appData.on_on_conf_add_uri )
        else
            session:setVariable("fsd_on_conf_add_uri",  baseOnConfAddURL )
            appData.on_conf_add_uri = baseOnConfAddURL
        end

        if appData.on_conf_answer_uri  ~= nil then
            session:setVariable("fsd_on_conf_answer_uri",  appData.on_on_conf_answer_uri )
        else
            session:setVariable("fsd_on_conf_answer_uri",  baseOnConfAnswerURL )
            appData.on_conf_answer_uri = baseOnConfAnswerURL
        end

        if appData.pre_call_prompt ~= nil then
            session:setVariable("fsd_on_call_end_uri", 	appData.on_call_end_uri )
        else
            session:setVariable("fsd_on_call_end_uri", 	baseOnCallEndURL )
            appData.on_call_end_uri = baseOnCallEndURL
        end

        -- -----------------------------------------------------------------------
        -- Create FS Origination string which is returned to FS XML code to "bridge" calls
        --   See /etc/freeswitch/conf/dialplan/fsDialer.xml
        --   <action application="bridge" data="${obString}"/>
        -- -----------------------------------------------------------------------

        if tonumber( appData.allow_call ) == 0 then     -- do not allow call
            fsLogWarn( "*******  Call Not Allowed allow_call = 0 *****" )
            playCallNotAllowed()
        else  -- Let the call go through


            if appData.to_addresses ~= nil then  -- combo 
                session:setVariable("fsd_call_term_type", "multiple" )
                appData.call_term_type = "multiple"
                createComboObString()

            elseif tostring( appData.p_or_s ) == "s" then  -- softphone 
                session:setVariable("fsd_call_term_type", "softphone" )
                appData.call_term_type = "softphone"
                fsLogWarn( "Terminating to Softphone" )

                appData.to_addresses = {}
                appData.to_addresses[1] = string.format("%s@%s", appData.to_address, default_domain)

                createComboObString()
            elseif tostring( appData.p_or_s ) == "p" then  -- pstn 
                session:setVariable("fsd_call_term_type", "pstn" )
                appData.call_term_type = "pstn"
                fsLogWarn( "Terminating to PSTN" )

                appData.to_addresses = {}
                appData.to_addresses[1] = appData.to_address

                createComboObString()
            else
                fsLogError( "*******  IN Error (Else) case for making a call *****" )
                playCallNotAllowed()
            end
        end
	
    end

	-- session:execute("info")

    fsLogDebug( "\n----- appData After Processing ------\n" ..  to_string( appData ) .. "\n--------------------------");

    fsLogDebug( api:executeString('uuid_dump ' .. myUuid )); 

else  -- Error with Session after getting here 
    freeswitch.consoleLog("DEBUG", "\n*******  NO SESSION for onInboundCall.lua \n" )
end


fsLogInfo( "*******  END of onInboundCall.lua  *****" )

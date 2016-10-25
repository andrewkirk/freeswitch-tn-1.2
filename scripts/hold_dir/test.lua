#!/usr/bin/lua 

myarray = {"one", "two", "three", "four"}
myarray[5] = "five"
table.insert(myarray, "six")

myarray['name'] = "james"

pOutString = "=====App Data=====\n"
for k, v in pairs(myarray) do
	pOutString=string.format("%sk=%s, v=%s\n", pOutString, tostring(k), tostring(v))
end
print(pOutString)

print("Name: " .. myarray.name )

local onNetTnList = {}
local onNetTnExt = {}
onNetTnList['18014712100'] = 1
onNetTnList['17202791225'] = 1
onNetTnList['17202797684'] = 1
onNetTnExt['17202797684'] = "0001,0016"
onNetTnList['17202797891'] = 1
onNetTnList['17202799791'] = 1
onNetTnList['17203813446'] = 5
onNetTnExt['17203813446'] = "0004,0012"

-- return 1 if tn is in onNetTnList else return 0
function isTnOnNet( tn )
	return onNetTnList[tn] and 1 or 0
end

print( "onNet = " .. isTnOnNet( "17203813446" ) )

function isTnOnNetTime( tn )
	return onNetTnList[tn] and onNetTnList[tn] or 0
end

-- string.match("132131_79878", "(.-)_")

print( "onNet = " .. isTnOnNetTime( "17203813446" ) )

local foo = "this_is_an_line"

local fooArray = {}

fooArray = foo:gmatch("_")

function isGogiiTN( fromTN, toTN )
	return isTnOnNet( fromTN ) == 1 and isTnOnNet( fromTN ) or isTnOnNet( toTN )
end

function returnGogiiTN( fromTN, toTN )
	return isTnOnNet( fromTN ) == 1 and fromTN or ( isTnOnNet( toTN ) == 1 and toTN or "" )
end

function returnGogiiExtensions( toTN )
	return isTnOnNet( toTN ) == 1 and ( onNetTnExt[ toTN ] and onNetTnExt[ toTN ] or "" ) or ""
end

function isApp2App( fromTN, toTN )
	return isTnOnNet( fromTN ) == 1 and ( isTnOnNet( toTN ) == 1 and 1 or 0 ) or 0
end

print( "isGogiiTN = " .. isGogiiTN( "1720279789", "17202797891" ) )
print( "returnGogiiTN = " .. returnGogiiTN( "1720279789", "17202797891" ) )
print( "returnGogiiExtensions = " .. returnGogiiExtensions( "17202799791" ) )
print( "isApp2App = " .. isApp2App( "17202799791", "17203813446" ) )

function string:split(sep)
        local sep, fields = sep or ",", {}
        local pattern = string.format("([^%s]+)", sep)
        self:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end

local foo = "123,456,,,789,000"
print(foo)

local fA = foo:split(",")

pOutString = "=====fA Data=====\n"
for k, v in pairs(fA) do
	pOutString=string.format("%sk=%s, v=%s\n", pOutString, tostring(k), tostring(v))
end
print(pOutString)


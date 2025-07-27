/* ReadParameters.rexx
Program to read the Roadshow send and receive parameters based on the type of connection and set environment variables
*/

vConnectionTypeArg=ARG(1)

RoadshowParametersFile='Sys:Pistorm/RoadshowParameters'


IF ~EXISTS(RoadshowParametersFile) THEN do
    SAY "Parameters file 'Sys:Pistorm/RoadshowParameters' does not exist!"
    exit 5
END


open(vRoadshowParameters,RoadshowParametersFile,'read') 
    do until eof(vRoadshowParameters)
        vRoadshowParameterLine=readln(vRoadshowParameters)
        parse var vRoadshowParameterLine vConnectionType';'vParameterName';'vParameterValue
        if vConnectionType=vConnectionTypeArg then do
            vCmd="setenv "vParameterName vParameterValue
            address command vCmd 
        end
    end 
Close(vParameters)
        

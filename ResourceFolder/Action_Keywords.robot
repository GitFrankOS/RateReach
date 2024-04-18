*** Settings ***
### Adtran 
Library        SeleniumLibrary     WITH NAME    selen   
Library        String
Library        OperatingSystem
Library        Process

## RG laptop 
Library        SSHLibrary         WITH NAME    SSH

## Test Sentinel
Library        RequestsLibrary
Library        Collections
Library        XML                WITH NAME    xml

*** Keywords ***
ADTRAN_CALL
    Register Keyword To Run On Failure      NONE    #Prevent taking screenshot if keyword failed
    Open Browser      ${Adtran_IP}    chrome    service_log_path=${{os.path.devnull}} 
    Set Window Size   1200  1000 
    Wait Until Element Is Visible   //*[@id="LogoImage"]  20s
    sleep  1 
    selen.Input Text    //*[@id="l_usrnm"]    ${Adtran_userName}    clear=True
    Input Password    //input[@id='l_pswrd']    ${Adtran_passWord}    clear=True
    Click Element    //input[@id='loginbutton']    # click Log on button  
    Wait Until Page Contains    ADMIN User Statistics  20s
    sleep  1
    Click Button    //input[@id='overlay_ok']    #Click OK button to continue
    Wait Until Page Contains    Total Access  20s   # Verify page contains Total Access
    sleep  3s
    Wait Until Element Is Visible    //*[@id="slot3"]  20s  #Check for Modules>3-Combo V2
    sleep  3s
    Click Element    //span[contains(text(), '${module}')]   ## click on module with text 3-Combo V2
    Wait Until Page Contains    Configuration  120s  #Verify page contains Configuration
    sleep  3s
    Click Element    //*[@id="modNavA_Prov"]   # Click Provision tab
    Wait Until Page Contains    Card Provisioning  30s  #Verify page contains Card Provisioning
    sleep  3s
    Click Element    //*[@id="ProvEvcMapPageTab_A"]  # Click Interface Map 
    Wait Until Element Is Visible    //*[@id="evcmap_LastError1_Display"]  30s  #wait until 1st row status is visible
    sleep  3s
    ## Look for text RR 3/2 ATM on page, click next if not found
    FOR    ${index}    IN RANGE    10
        ${textCheck}    Run Keyword And Return Status    Page Should Contain    ${interfaceMap}
        Log To Console    \nText present: ${textCheck}
        IF    ${textCheck} == True
            Click Element       //a[contains(text(),'${interfaceMap}')]
            Wait Until Page Contains    Edit Interface Map    30s
            Exit For Loop   # Exit "For Loop" to continue script           
        ELSE
            Click Element    //*[@id="evcmapListTable_NextBtn"]   # Click 'Next' button
            Wait Until Page Contains    Running     30s           
        END           
    END
    ## Get ID for Group, since this is dynamically changed
    ${id_value}=  selen.Get Element Attribute  //a[contains(text(),'${interfaceMap}')]  id  ## need this cause ID is dynamic
    ${id_regexp}=    Get Regexp Matches    ${id_value}    \\d+    #Regular expression to get ID number
    ${interfaceMapID}=    Set Variable    ${id_regexp}[0]      
    Log To Console    \nInterface Map ID for ${interfaceMap} group is: ${interfaceMapID}   
    ## Check status for ID 
    ${status}=  selen.Get Text    //span[@id='evcmap_LastError${interfaceMapID}_Display']
    Log To Console    \Current status is : ${status}
    Run Keyword     Should Be Equal As Strings  ${status}  Running  Fail: ${interfaceMap} status in not "Running"  
    ## Edit Interface     
    Select From List By Label    //select[@id='EVCMapAdminStatus']    ${serviceState}    #Servive State
    Sleep    1s
    Select From List By Label    //select[@id='EVCMapIPHost']    ${port}   #Port assignment (1/3/2)
    Sleep    1s
    Select From List By Label    //select[@id='EVCMapEvcName']    ${EVC_name}   #EVC Name
    Sleep    1s
    Select From List By Label    //select[@id='EVCMapCTagVLANID']    ${C_Tag}    # C-Tag
    Sleep    1s
    Select From List By Label    //select[@id='EVCMapDHCPProcess']    ${DHCP_Processing}    # DHCP Processing (Block)
    Sleep    1s
    Select from list by Label    //select[@id='EVCMapPPPoEProcess']    ${PPPoE_Processing}   #PPPoE Processing (Authenticate)
    Sleep    1s
    Click Element    //input[@id='EVCMap_ApplyBtn']    #click apply button
    Sleep    5s
    Log To Console    \n Complete Adtran configure
    Close Browser

### Test Sentinel API call
TS_API_CALL
    Create Session    fullurl    ${TS_baseURL}    # Test Sentinel #1
    ${xml}=   OperatingSystem.Get File  ${TS_xml_data} 
    ${resp}=    POST On Session    fullurl   TestSentinel     data=${xml}
    Log to console    	  \nAPI response: ${resp.content}
    ### Get Queue test id
    ${root}=    Parse XML    ${resp.content}
    ${QTestID}=    Get Element Text    ${root}    .//QueuedTestId
    Log To Console    \n Current Queded test ID: ${QTestID}

##### Check current Status save this to analyze
    FOR    ${index}    IN RANGE    20    # this set to 10 minutes
        ${xml}=    Set Variable    <GetTestStatus><QueuedTestId>${QTestID}</QueuedTestId></GetTestStatus>
        ${resp}=    POST On Session    fullurl   TestSentinel     data=${xml}
        Log to console   \nTest Status response is:\n${resp.content}
        
        ${root}=    Parse XML    ${resp.content}   
        ${status_element}=    Run Keyword And Return Status    Get Element    ${root}    .//Status  # return boolean
        ${status}=    Run Keyword If    ${status_element}    Get Element Text    ${root}    .//Status  #run keyword if ${status_element}=True
        Log To Console    \status is: ${status}

        Run Keyword If   '${status}' == 'finished' or '${status}' == 'crashed' or '${status}' == 'stopped'    Exit For Loop
        Sleep    30s

    END
    Run Keyword And Continue On Failure   Should Be Equal    '${status}'   'finished'    msg= TS did not completed after 10 minutes

    SSH.Close All Connections

### RG Laptop
RG_LAPTOP_CALL
    ${session}=  Open Connection    ${RG_host}        alias=${alias}
    Enable Ssh Logging    mySSHlogFile.log
    Login              ${RG_username}    ${RG_password}    delay=1
    sleep  2s
    
    #### below are used only to test command line to RG Laptop in place to TS #########################
    ${stdoutput}=   Execute Command    robot -d C:/Users/homeD/Desktop/DSL/Log_Folder -l RG_log.html -r RG_report.html -o RG_output.xml C:/Users/homeD/Desktop/DSL/RG_laptop.robot 
    # Log To Console    ${stdoutput}
    Run Keyword And Continue On Failure  Should Not Contain Any  ${stdoutput}  Error   FAIL  msg= Fail at RG_Laptop log  ignore_case=True  
    ${runStatus}=  Run Keyword And Return Status  Should Not Contain Any  ${stdoutput}  Error   FAIL  msg= Fail at RG_Laptop log  ignore_case=True 
    Log To Console    \n RG LAPTOP LOG STATUS: ${runStatus} 
    sleep  2
    #################################################################################### 

    ##### Get files from RG laptop
    ${Remote_folder_files}     SSH.List Files In Directory    ${remote_log_folder}
    FOR    ${file}    IN    @{Remote_folder_files}
        SSH.Get File    ${remote_log_folder}/${file}    ${local_log_folder}/${file}
    END
    Sleep   5s
    ### Check RG Laptop Output.XML Test Result 
    ${XML_FILE_PATH}    Set Variable    C:/Users/FrankOs/Desktop/RG_Laptop_log/output.xml  
    ${xml_file}=    OperatingSystem.Get File    ${XML_FILE_PATH}
    ${xml_content}=    Parse XML    ${xml_file}  
    ${stat_element}=    Get Element    ${xml_content}    xpath=.//statistics/suite/stat[@name='RG laptop']
    # Log To Console    ${stat_element}
    ${pass_count}=    XML.Get Element Attribute    ${stat_element}    pass
    Log To Console    \nPass\= ${pass_count}
    Run keyword and continue on Failure   Should Be True	${pass_count} > 0    msg:Test FAIL at RG laptop 
    
    
    Close All Connections

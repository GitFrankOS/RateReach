*** Settings ***
### Adtran 
Library        SeleniumLibrary    WITH NAME    selen   
Library        String
Library        OperatingSystem
Library        Process
# Resource       C:/Users/FrankOs/Desktop/CPE_Access/TestFolder/ADSL2+_Test/ResourceFolder/DSL_keywords.robot
Resource       ResourceFolder/Action_keywords.robot/

## RG laptop 
Library        SSHLibrary         WITH NAME    SSH

## Test Sentinel
Library        RequestsLibrary
Library        Collections
Library        XML                WITH NAME    xml

*** Variables ***
### Adtran variables
${Adtran_IP}              http://10.177.171.204    
${Adtran_userName}        ADMIN
${Adtran_passWord}        PASSWORD 
${module}                 Combo V2
${interfaceMap}           RR 3/2 ATM
${serviceState}           Active
${port}                   1/3/2
${EVC_name}               VLAN1000:1000
${C_Tag}                  1302
${DHCP_Processing}        Block
${PPPoE_Processing}       Authenticate

### Test Sentine Variables
${TS_baseURL}            http://10.177.173.163:2547    #Test Sentinel #1
${TS_endpoint}           TestSentinel
${TS_xml_data}           ResourceFolder/ADSL2+_ATM_120L1_Port2_API_328_ToQueue_Oneline.xml
# ${TS_xml_data}           C:\\Users\\FrankOs\\Desktop\\CPE_Access\\TestFolder\\ADSL2+_Test\\ResourceFolder\\ADSL2+_ATM_120L1_Port2_API_328_ToQueue_Oneline.xml

### RG laptop variables
${RG_host}                    10.177.173.169    # RG laptop #1
${RG_username}                homedemo06@outlook.com
${RG_password}                frontierHDR
${alias}                      remote_RG_170
${local_log_folder}           ResourceFolder/TC272LogFolder
${remote_log_folder}          C:/Users/homeD/Desktop/DSL/Log_Folder


*** Test Cases ***
Run All scripts

    Run Keyword And Continue On Failure    ADTRAN_CALL
    Sleep    3s
    # Run Keyword And Continue On Failure    TS_API_CALL
    # Sleep    5s
    Run Keyword And Continue On Failure    RG_LAPTOP_CALL


###### Add this to Test Sentinel "SendLine" python call to execute RG laptop RF scripts
##  robot -d C:/Users/homeD/Desktop/DSL/Log_Folder -l RG_log.html -r RG_report.html -o RG_output.xml C:/Users/homeD/Desktop/DSL/RG_laptop.robot 
##  robot -d ResourceFolder/TC272LogFolder TC272.robot    ###
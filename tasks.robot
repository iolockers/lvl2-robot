*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Desktop.Windows
Library             OperatingSystem
Library             RPA.Archive
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders} =     Get orders
    FOR    ${row}    IN    @{orders}
        TRY
            Close the annoying modal
            Fill the form    ${row}
            Preview the robot
            Submit the order
            ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
            ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
            Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
            Go to order another robot
        EXCEPT   
            Close order website
            Open the robot order website
        END
    END
    Zip Receipts Folder
    Close order website


*** Keywords ***
Open the robot order website
    ${ENV_VARIABLES}=           Get Secret        env_variables
    Open Available Browser      ${ENV_VARIABLES}[rsb_url]

Close the annoying modal
    Click Button    OK

Get orders
    ${ENV_VARIABLES}=    Get Secret        env_variables
    Download             ${ENV_VARIABLES}[orders_url]    overwrite=True
    ${orders}=           Read table from CSV    orders.csv
    RETURN               ${orders}

Fill the form
    [Arguments]                           ${order}
    Select From List By Value             head    ${order}[Head]
    Select Radio Button                   body    ${order}[Body]
    Input Text When Element Is Visible    css:input[placeholder="Enter the part number for the legs"]    ${order}[Legs] 
    Input Text                            id:address    ${order}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    WHILE   True    limit=10
        TRY
            Click Button                     id:order
            Wait Until Element Is Visible    id:receipt
            BREAK
        EXCEPT
            Log    Error loading the page
        END
    END

Store the receipt as a PDF file
    [Arguments]        ${order_number}
    ${order_html}=     Get Element Attribute    id:receipt    outerHTML
    Html To Pdf        ${order_html}    ${OUTPUT_DIR}${/}receipts/${order_number}.pdf
    RETURN             ${OUTPUT_DIR}${/}receipts/${order_number}.pdf

Take a screenshot of the robot    
    [Arguments]                      ${order_number}
    Wait Until Element Is Enabled    id:robot-preview-image
    Capture Element Screenshot       id:robot-preview-image    ${OUTPUT_DIR}${/}receipts/${order_number}.png
    RETURN                           ${OUTPUT_DIR}${/}receipts/${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]         ${screenshot}    ${pdf}
    @{files}=           Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}
    TRY
        Remove File     ${screenshot}
    EXCEPT    
        Log             File does not exist     
    END

Close order website
    Close Browser

Go to order another robot
    Click Button    order-another

Zip Receipts Folder
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip
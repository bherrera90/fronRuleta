×
Core Request
{
    "dinHeader": {
        "aplicacionId": "TCHNSY",
        "canalId": "MB",
        "uuid": "250011611365776237885941779738807561070:6b37b54f-88d0-4b98-a484-1019ad047dcf",
        "sesionId": "6b37b54f-88d0-4b98-a484-1019ad047dcf",
        "ip": "157.100.113.104",
        "horaTransaccion": "2025-07-15T16:04:30.00200",
        "nivelTrace": "DEBUG",
        "nombreServicio": "singleSelectConsumptionDifferPayment",
        "llaveSimetrica": "",
        "portalId": "PBN",
        "paginado": {
            "cantRegistros": "0",
            "numTotalPag": "0",
            "numPagActual": "0"
        },
        "externalUser": "SOPORTCASH1",
        "usuario": "SOPORTCASH1"
    },
    "dinBody": {
        "entidad": "ID",
        "marca": "VI",
        "tipoTarjeta": "P",
        "numeroTarjeta": "ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=",
        "numeroIdentificacion": "1713443644E",
        "listaTotalAbonar": [
            {
                "numeroTarjetaDiferido": "ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=",
                "codigoEstablecimiento": "1024232272",
                "numeroBoleta": "1856005",
                "numeroRecap": "98828",
                "numeroVale": "535252",
                "fechaVale": "20300723",
                "codigoAjuste": "807",
                "saldoPendienteFecha": "12.01",
                "valorAbono": "12.00",
                "saldoPendiente": "12.31",
                "saldoPendienteAbono": "",
                "valorCuotaAbono": ""
            },
            {
                "numeroTarjetaDiferido": "ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=",
                "codigoEstablecimiento": "1024232272",
                "numeroBoleta": "1856005",
                "numeroRecap": "98828",
                "numeroVale": "535253",
                "fechaVale": "20300723",
                "codigoAjuste": "807",
                "saldoPendienteFecha": "11.53",
                "valorAbono": "3.00",
                "saldoPendiente": "11.82",
                "saldoPendienteAbono": "8.76",
                "valorCuotaAbono": "2.92"
            }
        ]
    }
}


Mountain View TECH Service Tracing Tool - 

Service Tracing
Search:	.	
Show  entries
Search:
Service Name	CMM Request	CMM Response	Core Request	Core Response	Branch	Error Code	ElapsedTime	Time RQ	Time RS
singleSelectConsumptionDifferPayment	<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:e="http://www.technisys.net/cmm/services/errors/v1.0" xmlns:md="http://www.technisys.net/cmm/services/metadata/v2.0" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <SOAP-ENV:Header> <md:metadata> <serviceId>singleSelectConsumptionDifferPayment</serviceId> <serviceVersion>1.0</serviceVersion> <sessionId>6b37b54f-88d0-4b98-a484-1019ad047dcf</sessionId> <applicationId/> <traceNumber>11759756063693649068028246252190188100.250011611365776237885941779738807561070</traceNumber> <channelId>MB</channelId> <targetChannel> <mnemonic>MB</mnemonic> </targetChannel> <organizationType> <mnemonic/> </organizationType> <executingChannel> <mnemonic>MB</mnemonic> </executingChannel> <address>ip=157.100.113.104;</address> <executingOperatorId>uriTech=OPERADOR_EMPRESA@16552;uriSFB=2#1713443644E;uriRUC=3#1713443644E;OWNER=true</executingOperatorId> <locale>ES</locale> <institutionType/> <template> <templateId/> </template> <channelDispatchDate>20250715160430200-0500</channelDispatchDate> <msgTypeId/> <workflowModule/> <featureId>ROL@5739</featureId> <sourceDate/> <workflowId/> <businessDate/> <terminalId>Blu%20by%20Diners%20Club/328 CFNetwork/1410.1 Darwin/22.6.0</terminalId> <sourceTime/> <branchId/> <userId/> <executingScope/> <customProperties> <operatorId type="java.lang.String"/> <businessDate type="java.util.Date"/> <serviceContext type="java.lang.String"/> <llaveSimetrica type="java.lang.String"/> <funcCode type="java.lang.String"/> <funcType type="java.lang.String">PCU</funcType> <terminal type="java.lang.String"/> <portal type="java.lang.String">PBN</portal> <deviceId type="java.lang.String"/> </customProperties> <llaveSimetrica type="java.lang.String"/> <organizationOperatorId>userName=SOPORTCASH1</organizationOperatorId> <parityCurrencyId/> <localCurrencyId/> <institutionId/> <localCountryId/> <bankId/> <ip>157.100.113.104</ip> <parityQuotationNemonic/> <paginationInfo/> <internals> <auditCore>true</auditCore> <autoPaginationEnabled>false</autoPaginationEnabled> <serviceProviderEntityName>LOCAL</serviceProviderEntityName> <serviceProviderName>DINERS</serviceProviderName> <translate>true</translate> <serviceRequestTimestamp/> </internals> </md:metadata> </SOAP-ENV:Header> <SOAP-ENV:Body> <NS3:singleSelectConsumptionDifferPaymentRequest xmlns:NS3="http://www.technisys.net/cmm/services/singleSelectConsumptionDifferPayment/rq/v1.0"> <creditCard dataModel="diners.financials" name="creditCard" version="1.0"> <entityCode>ID</entityCode> <numberOnCard>ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=</numberOnCard> <creditCardAccount> <brand> <mnemonic>VI</mnemonic> </brand> </creditCardAccount> <creditCardCategory> <mnemonic>P</mnemonic> </creditCardCategory> </creditCard> <customer dataModel="diners.financials" name="customer" version="1.0"> <customerId>1713443644E</customerId> </customer> <consumptionMovs dataModel="diners.financials" name="consumptionMovs" version="1.0"> <consumptionMovs> <consumptionValue>12.31</consumptionValue> <amountToPay>4.11</amountToPay> <ticketNumber>1856005</ticketNumber> <amountPending>12.01</amountPending> <establishment> <number>1024232272</number> <name>CASH ADVANCE PR</name> </establishment> <accountNumber>807</accountNumber> <paymentType>S</paymentType> <reference>2064395</reference> <consumptionValeDate>20300723</consumptionValeDate> <numeroVale>535252</numeroVale> <recapNumber>98828</recapNumber> <amountNewTodiffer>12.31</amountNewTodiffer> <creditCard> <numberOnCardDeferred>ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=</numberOnCardDeferred> </creditCard> <currencyCode>1</currencyCode> <paymentNumber>3</paymentNumber> <paymentNumberToPay>3</paymentNumberToPay> <voucherNumber>535252</voucherNumber> <amountToPayEdit>12.00</amountToPayEdit> </consumptionMovs> <consumptionMovs> <consumptionValue>11.82</consumptionValue> <amountToPay>3.94</amountToPay> <ticketNumber>1856005</ticketNumber> <amountPending>11.53</amountPending> <establishment> <number>1024232272</number> <name>CASH ADVANCE PR</name> </establishment> <accountNumber>807</accountNumber> <paymentType>S</paymentType> <reference>2064395</reference> <consumptionValeDate>20300723</consumptionValeDate> <numeroVale>535253</numeroVale> <recapNumber>98828</recapNumber> <amountNewTodiffer>11.82</amountNewTodiffer> <creditCard> <numberOnCardDeferred>ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=</numberOnCardDeferred> </creditCard> <currencyCode>1</currencyCode> <paymentNumber>3</paymentNumber> <paymentNumberToPay>3</paymentNumberToPay> <voucherNumber>535253</voucherNumber> <amountToPayEdit>3.00</amountToPayEdit> <valueFee>2.92</valueFee> <ammountConsumptionCurrent>8.76</ammountConsumptionCurrent> </consumptionMovs> </consumptionMovs> </NS3:singleSelectConsumptionDifferPaymentRequest> </SOAP-ENV:Body> </SOAP-ENV:Envelope>	<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:e="http://www.technisys.net/cmm/services/errors/v1.0" xmlns:md="http://www.technisys.net/cmm/services/metadata/v2.0"> <soap:Header> <md:metadata> <internals> <serviceProviderEntityName>LOCAL</serviceProviderEntityName> <serviceProviderName>DINERS</serviceProviderName> </internals> <executingChannel> <mnemonic translationError="UNDEFINED_TRANSLATION">MB</mnemonic> <originalCodes>originalCode=MB;</originalCodes> </executingChannel> <locale>ES</locale> <md:serviceId>singleSelectConsumptionDifferPayment</md:serviceId> <md:serviceVersion>1.0</md:serviceVersion> </md:metadata> </soap:Header> <soap:Body> <soap:Fault> <soap:Detail> <e:errors> <error> <severity>ERROR</severity> <source>Error al invocar servicio https://msd-pro-tar-dc-diferidos-calcula-gsf-dinersclub-migracion-gsf.apps.din-ros-can-dev.9gqx.p1.openshiftapps.com/productos/v1/tarjetas-credito/abonos-diferidos/abonos/calcula</source> <sourceCode>1.0</sourceCode> <detail>500 Internal Server Error: "{"dinHeader":{"aplicacionId":"TCHNSY","canalId":"MB","sesionId":"6b37b54f-88d0-4b98-a484-1019ad047dcf","dispositivo":null,"idioma":null,"portalId":"PBN","uuid":"250011611365776237885941779738807561070:6b37b54f-88d0-4b98-a484-1019ad047dcf","ip":"157.100.113.104","horaTransaccion":"2025-07-15T16:04:30.00200","llaveSimetrica":"","usuario":"SOPORTCASH1","paginado":{"cantRegistros":0,"numTotalPag":0,"numPagActual":0},"tags":null},"dinBody":null,"dinError":{"tipo":"T","fecha":"2025-07-15T21:04:30.495GMT","origen":null,"codigo":"9999","codigoErrorProveedor":null,"mensaje":null,"detalle":"java.lang.NumberFormatException"}}"</detail> <origin>CoreServiceInvocationException</origin> <cmmCode>UNKNOWN_ERROR</cmmCode> <cmmMsg>En estos momentos no lo podemos atender, por favor intentelo mas tarde.</cmmMsg> <kind>GENERIC</kind> </error> </e:errors> </soap:Detail> </soap:Fault> </soap:Body> </soap:Envelope>	{ "dinHeader": { "aplicacionId": "TCHNSY", "canalId": "MB", "uuid": "250011611365776237885941779738807561070:6b37b54f-88d0-4b98-a484-1019ad047dcf", "sesionId": "6b37b54f-88d0-4b98-a484-1019ad047dcf", "ip": "157.100.113.104", "horaTransaccion": "2025-07-15T16:04:30.00200", "nivelTrace": "DEBUG", "nombreServicio": "singleSelectConsumptionDifferPayment", "llaveSimetrica": "", "portalId": "PBN", "paginado": { "cantRegistros": "0", "numTotalPag": "0", "numPagActual": "0" }, "externalUser": "SOPORTCASH1", "usuario": "SOPORTCASH1" }, "dinBody": { "entidad": "ID", "marca": "VI", "tipoTarjeta": "P", "numeroTarjeta": "ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=", "numeroIdentificacion": "1713443644E", "listaTotalAbonar": [ { "numeroTarjetaDiferido": "ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=", "codigoEstablecimiento": "1024232272", "numeroBoleta": "1856005", "numeroRecap": "98828", "numeroVale": "535252", "fechaVale": "20300723", "codigoAjuste": "807", "saldoPendienteFecha": "12.01", "valorAbono": "12.00", "saldoPendiente": "12.31", "saldoPendienteAbono": "", "valorCuotaAbono": "" }, { "numeroTarjetaDiferido": "ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=", "codigoEstablecimiento": "1024232272", "numeroBoleta": "1856005", "numeroRecap": "98828", "numeroVale": "535253", "fechaVale": "20300723", "codigoAjuste": "807", "saldoPendienteFecha": "11.53", "valorAbono": "3.00", "saldoPendiente": "11.82", "saldoPendienteAbono": "8.76", "valorCuotaAbono": "2.92" } ] } }	{ "dinHeader": { "aplicacionId": "TCHNSY", "canalId": "MB", "sesionId": "6b37b54f-88d0-4b98-a484-1019ad047dcf", "dispositivo": null, "idioma": null, "portalId": "PBN", "uuid": "250011611365776237885941779738807561070:6b37b54f-88d0-4b98-a484-1019ad047dcf", "ip": "157.100.113.104", "horaTransaccion": "2025-07-15T16:04:30.00200", "llaveSimetrica": "", "usuario": "SOPORTCASH1", "paginado": { "cantRegistros": 0, "numTotalPag": 0, "numPagActual": 0 }, "tags": null }, "dinBody": null, "dinError": { "tipo": "T", "fecha": "2025-07-15T21:04:30.495GMT", "origen": null, "codigo": "9999", "codigoErrorProveedor": null, "mensaje": null, "detalle": "java.lang.NumberFormatException" } }		1.0	0.30 ss	2025-07-15 16:04:30.207	2025-07-15 16:04:30.510
Showing 1 to 1 of 1 entries
Previous1Next
Timelines Tracing
singleSelectConsumptionDifferPayment-MB
TimeStartRQ: 16:04:30.207 / operationId: 250011611365776237885941779738807561070 / ElapseTime Director: 0.30 ss
ServiceId	description	Start	End
singleSelectConsumptionDifferPayment-MB	TimeStartRQ: 16:04:30.207 / operationId: 250011611365776237885941779738807561070 / ElapseTime Director: 0.30 ss	Jul 15, 2025	Jul 15, 2025


{
    "dinHeader": {
        "aplicacionId": "TCHNSY",
        "canalId": "MB",
        "uuid": "241810606954904443639356354181789775477:d2f8f3a5-e227-4f7a-8265-27ddbb3838c6",
        "sesionId": "d2f8f3a5-e227-4f7a-8265-27ddbb3838c6",
        "ip": "181.199.60.180",
        "horaTransaccion": "2025-07-08T09:14:12.00900",
        "nivelTrace": "DEBUG",
        "nombreServicio": "singleSelectConsumptionDifferPayment",
        "llaveSimetrica": "",
        "portalId": "PBN",
        "paginado": {
            "cantRegistros": "0",
            "numTotalPag": "0",
            "numPagActual": "0"
        },
        "externalUser": "SOPORTCASH1",
        "usuario": "SOPORTCASH1"
    },
    "dinBody": {
        "entidad": "ID",
        "marca": "VI",
        "tipoTarjeta": "P",
        "numeroTarjeta": "ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=",
        "numeroIdentificacion": "1713443644E",
        "listaTotalAbonar": [
            {
                "numeroTarjetaDiferido": "ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=",
                "codigoEstablecimiento": "1024232272",
                "numeroBoleta": "1856005",
                "numeroRecap": "98828",
                "numeroVale": "535249",
                "fechaVale": "20300723",
                "codigoAjuste": "807",
                "saldoPendienteFecha": "101.73",
                "valorAbono": "50.20",
                "saldoPendiente": "104.07",
                "saldoPendienteAbono": "52.74",
                "valorCuotaAbono": "17.58"
            },
            {
                "numeroTarjetaDiferido": "ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=",
                "codigoEstablecimiento": "1024232272",
                "numeroBoleta": "1856005",
                "numeroRecap": "98828",
                "numeroVale": "535250",
                "fechaVale": "20300723",
                "codigoAjuste": "807",
                "saldoPendienteFecha": "101.73",
                "valorAbono": "60.40",
                "saldoPendiente": "104.07",
                "saldoPendienteAbono": "42.3",
                "valorCuotaAbono": "14.1"
            },
            {
                "numeroTarjetaDiferido": "ht7VhvnOIQnEai6KWLBahc/UBsPEWUpwZnK9qA2g8W0=",
                "codigoEstablecimiento": "1024232272",
                "numeroBoleta": "1856005",
                "numeroRecap": "98828",
                "numeroVale": "535251",
                "fechaVale": "20300723",
                "codigoAjuste": "807",
                "saldoPendienteFecha": "101.23",
                "valorAbono": "50.30",
                "saldoPendiente": "103.56",
                "saldoPendienteAbono": "52.13",
                "valorCuotaAbono": "17.38"
            }
        ]
    }
}
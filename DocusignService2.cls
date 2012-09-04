/*
/*
    Class Name: DocusignServices2
    Author: Ram
    Description: Common Util class used for docusign contract signing process (PDF content)
   
 */


public with sharing class DocusignServices2 {

	//Get Authenticaion Header, Used for all request
	public static String authHeader(){
		//Get Paramter from Custom Setting (sfdc cache) and construct auth header
		return '<DocuSignCredentials>'+
					'<Username>'+Docusign_Settings__c.getValues('Username').value__c+'</Username>'+
					'<Password>'+Docusign_Settings__c.getValues('Password').value__c+'</Password>'+
					'<IntegratorKey>'+Docusign_Settings__c.getValues('IntegratorKey').value__c+'</IntegratorKey>'+
				'</DocuSignCredentials>';
	}
	
	//Process Document for sending to Docusign
	public static Pagereference processDocument(Id ctrId){
		//Account Id
		String accId = Docusign_Settings__c.getValues('accountId').value__c;
		//Create Draft Envelope
		String envId = createEnvelope(accId);
		if(envId!=null){
			//Attach Document
			attachDocToDS(envId, ctrId, accId);
			//Send envelope
			sendToDS(envId, accId);
		}
		return new Pagereference('/'+ctrId);
	}
	
	//Create Draft Envelope Method 
	public static String createEnvelope(String accKey){
		String passString = authHeader();					
		//MyBoundary - used to indicate benging/end of document in multi-part request
		String contentType = '\r\n--myBoundary'+'\r\n'+' Content-Type: application/json'+ '\r\n'+' Content-Disposition: form-data'+'\r\n\r\n';
		String envelop = DocusignServices2.createJSONString();
		System.debug('request body => '+envelop);
		String envEOF = '\r\n'+'--myBoundary--';					
		Http httpProtocol = new Http();
		HttpRequest request = new HttpRequest();
		String endpoint = 'https://demo.docusign.net/restapi/v2/accounts/'+accKey+'/envelopes';
		request.setEndPoint(endpoint);
		request.setMethod('POST');
		request.setHeader('Accept', 'application/json');
		request.setHeader('X-DocuSign-Authentication', passString);
		request.setHeader('content-type', 'multipart/form-data;boundary=myBoundary'); 
		System.debug('Request Body = '+contentType+''+envelop+''+envEOF);
		request.setBody(contentType+''+envelop+''+envEOF);
		HttpResponse response1 = httpProtocol.send(request);
		System.debug('response1 =>'+response1.getBody());
		JSONParser parse = JSON.createParser(response1.getBody());
		EnvResponse envstat = (EnvResponse)parse.readValueAs(EnvResponse.class);
		System.debug('De-Serialized class is envstats => '+envstat);
		return envstat.envelopeId;
	}
	
	
	//Attach Document to Draft Envelope
	public static void attachDocToDS(String envId, Id ctrId, String accKey){
		String passString = authHeader();
		Http httpProtocol = new Http();
		String endpoint = 'https://demo.docusign.net/restapi/v2/accounts/'+accKey+'/envelopes/'+envid+'/documents/1';
		System.debug('End Point => '+endpoint);
		//Send PDF
		PageReference pageRef = new PageReference('/apex/contractpdf');
		//Contract Id for PDF
		pageRef.getParameters().put('id',ctrId);
     	Blob b = pageRef.getContentaspdf();
		// Create HTTP request to send.
		HttpRequest request2 = new HttpRequest();
		request2.setEndPoint(endpoint);
		// Set the HTTP verb to GET.
		request2.setMethod('PUT');
		request2.setHeader('Accept', 'application/json');
		request2.setHeader('X-DocuSign-Authentication', passString);
		request2.setHeader('content-length', String.valueOf(b.size()));
		request2.setHeader('content-type', 'application/pdf;Content-Disposition: file; filename=contract.pdf; documentid=1; fileExtension=pdf');
		request2.setHeader('Content-Disposition', 'file; filename=contract.pdf; documentid=1; fileExtension=pdf');
		request2.setBodyAsBlob(b);
		HttpResponse response2 = httpProtocol.send(request2);
		System.debug('response2 header =>'+response2.getStatus()+', Body=> '+response2.getBody());
	}
	
	
	//Send Document for Signing
	public static void sendToDS(String envId, String accKey){
		String passString = authHeader();
		Http httpProtocol = new Http();
		String endpoint = 'https://demo.docusign.net/restapi/v2/accounts/'+accKey+'/envelopes/'+envid;
		System.debug('End Point => '+endpoint);
		HttpRequest request2 = new HttpRequest();
		request2.setEndPoint(endpoint);
		// Set the HTTP verb to GET.
		request2.setMethod('PUT');
		request2.setHeader('Accept', 'application/json');
		request2.setHeader('X-DocuSign-Authentication', passString);
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeStringField('status', 'sent');
		gen.writeEndObject();
		String  body = gen.getAsString();
		System.debug('body => '+body);
		request2.setBody(body);
		HttpResponse response2 = httpProtocol.send(request2);
		System.debug('response2 header =>'+response2.getStatus()+', Body=> '+response2.getBody());
	}
	
	
	//Util helper for constructing JSON request 
	public static String createJSONString(){	
		List<Signers> recipients = new List<Signers>{new Signers('rpachaiyappan@gmail.com', 'Ram', '1', '1') };
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeStringField('emailBlurb', 'Please Sign Contracts ASAP!');
		gen.writeStringField('emailSubject', 'Docusign Contracts');
		gen.writeFieldName('recipients');
		gen.writeStartObject();
		gen.writeObjectField('signers',recipients);
		gen.writeEndObject();
		gen.writeStringField('status', 'created');
		gen.writeEndObject();
		System.debug('JSON String => '+gen.getAsString());
		return gen.getAsString();
	}
	
	//Signer Class
	public class Signers{
		String email;
		String name;
		String recipientId;
		String routingOrder;
		
		public Signers(String emailAddr, String nam, String recpId, String routId){
			email = emailAddr;
			name = nam;
			recipientId = recpId;
			routingOrder = routId;		
		}	
	}
	/*
	public class Tab{
		String name;
		public Tab(String n){
			name =n;
		}
	}*/
	
	//Envelope Data Class
	public class EnvResponse{
		String envelopeId;
		String 	status;
		String statusDateTime;
		String uri;
	}
}
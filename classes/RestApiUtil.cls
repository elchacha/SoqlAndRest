public class RestApiUtil {

    // Warning : this method does not easily give the parent value like : Account.Name
    // Records are send back a a map of <String,Object>
    // To retrieve the field reason, use  : result.get(i).get('reason'))
    public static List<Map<String, Object>> execute(String query,boolean keepAttributes){
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v47.0/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8'));
        req.setMethod('GET');
        HttpResponse res;
        if(Test.isRunningTest()){
            res = new HttpResponse();
        	res.setStatusCode(200);
            res.setBody('{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"CustomField","records":[{"attributes":{"type":"CustomField","url":"/services/data/v47.0/tooling/sobjects/CustomField/00N1j000005FXFKEA4"},"Id":"00N1j000005FXFKEA4"}]}');
        }else{
	        res = (new Http()).send(req);
        }
		Map<String, Object> fieldMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        List<Object> recordsMap =   (List<Object>)fieldMap.get('records');
        List<Map<String, Object>> result = new List<Map<String, Object>> ();
        // in case we would like to retrieve parent information, we would need to do recursive code to process all values of the map and for each object instanceOf Map,
        // we should redo the same operation
        for(Object anObj : recordsMap){
            Map<String, Object>objMap = (Map<String, Object>) anObj;
            if(!keepAttributes)objMap.remove('attributes');
            result.add(objMap);
        }        
        return result;
    }    
    
    public static List<SObject> execSosl(String query,String type){
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v47.0/search/?q='+EncodingUtil.urlEncode(query, 'UTF-8')); // use your own SOSL statement
        req.setMethod('GET');
        req.setHeader('Content-type', 'application/json');	
        
        Http http = new Http();
        HTTPResponse res;
        if(Test.isRunningTest()){
            res = RestApiUtil_Mock.getResponse(type);
        }else{
            res = http.send(req);
        }
        
        Search.SearchResults searchResults = (Search.SearchResults)JSON.deserialize(res.getBody(), Search.SearchResults.class);
        List<SObject> objects = new List<SObject>();
        if(searchResults!=null){
            try {
                List<Search.SearchResult> objectLists = searchResults.get(type);
                for (Search.SearchResult searchResult : objectLists) {
                    objects.add(searchResult.getSObject());
                }
            }
            catch (Exception e) {
                // si la liste ne contient rien, çà semble causer une erreur
            }
        }
        System.debug('res'+objects);
        return objects;
    }
    
    
    public static void updateObjects(List<sObject> records){
        updateObjects(records,20000);
    }
   	public static void updateObjects(List<sObject> records,Integer timeout){
        
        List<List<sObject>> partionLists = (List<List<sObject>>) Lists.doPartions(records, 200);
        for(List<sObject> minList : partionLists){
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
            req.setHeader('Content-Type', 'application/json');
	        req.setTimeout(timeout);            
            req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v47.0/composite/sobjects?_HttpMethod=PATCH');
            req.setBody(getRecords(minList,true));
            req.setMethod('POST');
            HttpResponse response = (new Http()).send(req);
            if(response.getStatusCode()!=200&&response.getStatusCode()!=201){
                throw new RestApiUtilException(response.getBody(),response.getStatusCode(),'/services/data/v47.0/composite/sobjects?_HttpMethod=PATCH',getRecords(records,true));
            }

        }
    }
    
    public class sObjectToSend{
       boolean allOrNone;
       List<sObject> records;
       public sObjectToSend(List<sObject> records,boolean allOrNone){
            this.allOrNone=allOrNone;
            this.records=records;
       }
    }
    
    private static String getRecords(List<sObject> records,boolean allOrNone){
        sObjectToSend recordsToSend = new sObjectToSend(records,true);
        for(sObject record : records)
            if(record.Id==null)
            	throw new RestApiUtilException('found an object with no Id : '+JSON.serialize(record, true));
        system.debug('updating : '+JSON.serialize(recordsToSend, true));
		return JSON.serialize(recordsToSend, true);
    }

    public static HttpResponse restUpsert(sObject obj){
        return restUpsert(obj,20000);
    }

    
    // cette méthode permet de réaliser une opération DML hors transaction et donc au milieu d'appel à d'autres webservice
    public static HttpResponse restUpsert(sObject obj,Integer timeout){
        HttpRequest req = new HttpRequest();
		Http http = new Http();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(timeout); 
        String upsertPart =obj.getSObjectType().getDescribe().getName();
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setMethod('POST');
        if(obj.Id!=null){
            upsertPart+='/'+obj.Id+'?_HttpMethod=PATCH';
	        obj.Id=null;
        }
        system.debug('restUpsertEndpoint > '+URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v47.0/sobjects/'+upsertPart);
        
        req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v47.0/sobjects/'+upsertPart);
        req.setBody(Json.serialize(obj, true).replaceAll(',"Id":null',''));
        system.debug('body>'+Json.serialize(obj, true).replaceAll(',"Id":null',''));
        
        HttpResponse res = http.send(req);
        system.debug(res.getStatusCode());
        system.debug(res.getBody());
        return res;
    }
    

    
    public class RestApiUtilException extends Exception{
        private integer code;
        public RestApiUtilException(String msg,integer code,String operation,String body){
            msg=null;
            if(msg!=null)
	            this(msg);
            else
                this('OpenPricer Operation /'+operation+' return with code : '+code+'\nBody was : '+body);
            this.code=code;
        }

    }
        
}
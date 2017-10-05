public class LogUtil {

  Public Static Void digestLog(Id LogFileId) {
      Log_File__c LogFile = [select ID, LogId__c from Log_File__c where Id = :LogFileId];
      
      if (LogFile!=null) {
          digestLog(LogFile);
      }
        
  }
  
  Public Static Void digestLog(Log_File__c LogFile) {
      //Delete Existing Log Lines
     // List<id> linesToDel = new List<id>();
     // For (Log_Line__c ll : [select id from Log_Line__c where Log_file__c = :LogFile.id]) {
      //    linesToDel.add(ll.id);
      //}
      //deleteLogLines(linesToDel);
      
            
      Id ApexLogId = LogFile.LogId__c;
      String LogBody = getBody(ApexLogId);
      List<Log_Line__c> LogLines = new List<Log_Line__c>();
      for(String line : LogBody.split('\n')) {
          Log_Line__c l = new Log_Line__c(Log_File__c = LogFile.id,  Log_Data__c = line );
          LogLines.add(l);
      }
      insert(LogLines);
  }
  
  
  Public static void deleteLines(List<Log_Line__c> DelLines) {
      If (DelLines.size() > 0) {
          delete DelLines;
          Database.emptyRecycleBin(DelLines);
      }  
  }
  
  Public static String getBody(Id ApexLogId) {
    // Instantiate a new http object
    String hostURL= 'https://na50.salesforce.com';
    String requestPath = '/services/data/v40.0/sobjects/ApexLog/' + ApexLogId + '/Body';
    
    Http h = new Http();

    // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
    HttpRequest req = new HttpRequest();
    req.setEndpoint(hostUrl + requestPath);
    req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
    req.setHeader('Content-Type', 'application/json');
    req.setMethod('GET');

    // Send the request, and return a response
    HttpResponse res = h.send(req);
    return res.getBody();
  }
    
}
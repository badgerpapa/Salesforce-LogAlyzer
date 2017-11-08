Public Class LogAlyzerController {
    Public Log_File__c LogFile {get; set;}
    Public Boolean logLinesExist {get; set;}

    
    Public LogAlyzerController() {
        Id LogFileId = System.currentPageReference().getParameters().get('Id');
        LogFile = [SELECT CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedDate,  LogId__c, Log_Processed__c, Log_Line_Count__c FROM Log_File__c where id = :LogFileId];
        logLinesExist = LogFile.Log_Line_Count__c > 0;
        System.debug('**********In Constructor*********');
    }
    
    Public List<Log_Line__c> getLogLines() {
        System.Debug('******Get Log Lines******');
        List<Log_Line__c> LogLines = new List<Log_Line__c>([SELECT Log_Data__c,Log_File__c, Comment__c FROM Log_Line__c where Log_File__c = :LogFile.id LIMIT 1000]);
        return LogLines;
        }
    
    
    Public PageReference DeleteLines() {
        System.Debug('******Deleting Log Lines*******');
        List<Log_Line__c> LinesToDelete = New List<Log_Line__c>([select id from Log_Line__c where Log_File__c = :LogFile.id]);
        system.debug(LinesToDelete);
        delete LinesToDelete;
        Database.emptyRecycleBin(LinesToDelete);
        LogFile.Status__c = 'New';
        update LogFile;
        return System.currentPageReference();
    }  

    Public PageReference Analyze() {
    		LogFile.Status__c = 'Analyzing';
    		update LogFile;
        return null;
    }
    
    Public PageReference OnePassDigest() {
        Integer PrevOffset = 0;
        Pattern InfoLinePat = Pattern.compile('(^\\d+(\\.\\d+)?) ((\\w+,\\w+;?)+)$');
        Pattern LogLinePat = Pattern.compile('^(\\d{1,2}:\\d{2}:\\d{2}\\.\\d+)\\s+\\((\\d+)\\)\\|((\\w+)\\|?(.+)*)$');
        List<Log_Line__c> LogLines = new List<Log_Line__c>();
        
        String LogBody = getBody(LogFile.LogId__c);
        
        for(String line : LogBody.split('\n')) {
            System.debug(line);
            If ((line != null && line.deleteWhitespace().length() > 0)) {
              
            Matcher MatchLogLine = LogLinePat.matcher(line);
            if (MatchLogLine.matches()) {
                /**System.debug('*****Log Line*******');
                System.debug('Time: ' + MatchLogLine.group(1));
                System.debug('Offset: ' + MatchLogLine.group(2));
                System.debug('Event Type: ' + MatchLogLine.group(4));
                System.debug('TheRest: ' + MatchLogLine.group(3));
                **/
                Integer Offset = Integer.valueOf(MatchLogLine.group(2));
                Integer ExecTime = Offset - PrevOffset;
                PrevOffset =  Offset;                     
                Log_Line__c l = new Log_Line__c(Log_File__c = LogFile.id
                                                , Log_Data__c = line
                                                , LogTime__c = MatchLogLine.group(1)
                                                , Execution_Time__c = ExecTime
                                                , Details__c = MatchLogLine.group(3)
                                                , Event_Type__c = MatchLogLine.group(4)
                                                , Offset_Time__c = Offset
                                                );
                LogLines.add(l);
                
              
          
             }
             else {
                
                    Matcher MatchInfoLine = InfoLinePat.matcher(line);
                    if (MatchInfoLine.matches()) {
                   /**     System.debug('*****Info Line*****');
                        System.debug('Version: ' + MatchInfoLine.group(1));
                        System.debug('Debug Level: ' + MatchInfoLine.group(3)); 
                      **/  
                        String LogLevel = '';
                        For(String s:  MatchInfoLine.group(3).split(';')) {
                            LogLevel = LogLevel + s + '\n';
                        }
                        LogFile.API_Version__c  =  MatchInfoLine.group(1);
                        LogFile.Log_Level__c = LogLevel;
                        
                        update LogFile;
                    }
                    else {
                    // Append non loggy lines to the previous line (validations, formulas, limits, etc)
                      
                        LogLines.get(LogLines.size() -1 ).Details__c = LogLines.get(LogLines.size() -1 ).Details__c + '\n' + line;   
                        LogLines.get(LogLines.size() -1 ).Log_Data__c = LogLines.get(LogLines.size() -1 ).Log_Data__c + '\n' + line;  
                     }
                }
            }
        }
        insert LogLines;
        LogFile.Status__c = 'Digested';
        update LogFile;
        Return System.currentPageReference();    
     }
     
  private String getBody(Id ApexLogId) {
    // Instantiate a new http object
    String hostURL= 'https://cs66.salesforce.com';
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
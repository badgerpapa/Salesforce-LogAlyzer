public class LogListAlyzerController {
    
    Private Map<String,Log_File__c> AnalysisMap;
    Public List<ApexLog> ApexLogs {get; set;}
    
    public LogListAlyzerController() {
        AnalysisMap = new Map<String,Log_File__c>();
        ApexLogs = [SELECT Application, Id, Location, LogLength, LogUser.Name, Operation, Request, StartTime, Status, DurationMilliseconds FROM ApexLog Order By StartTime Desc];
        For(Log_File__c l :[SELECT CreatedBy.Name, CreatedDate,Id,LogId__c,OwnerId FROM Log_File__c] ) {
            AnalysisMap.put(l.LogId__c, l);
        }
    }
    
    
    
    
    
    Public PageReference AnalyzeLog() {
        Id ApexLogId = System.currentPageReference().getParameters().get('ApexLogId');        
        
        //If the Log anaylysis has started, go to the page, otherwise create it
        Log_File__c Log_File = AnalysisMap.get(ApexLogId);
        
        if (Log_File == null) {
            Log_File = new Log_File__c(LogId__c = ApexLogId);

            insert Log_File;
        }
        PageReference Log_File_Page = New PageReference('/apex/LogAlyzer');
        Log_File_Page.getParameters().put('id',Log_File.id);
        Log_File_Page.setRedirect(true);
        return Log_File_Page;
            

    }
    

}
public class RestSoqlExamples {

    
    public static void createCases(){
        List<Case> cases = new List<Case>();
        for(integer i=0;i<10;i++){
            cases.add(new Case (reason='test1'));
            cases.add(new Case (reason='test2'));
            cases.add(new Case (reason='test3'));
        }
        insert cases;
    }
    
    public static void soqlAggregateWorkFine(){
        system.debug('executing : [select count() from case ]\nfound records : '+[select count() from case ]);
        system.debug('limits found : '+Limits.getQueryRows()+'/'+Limits.getLimitQueryRows());
        system.debug('we can see here that we just have consume 1 row , aggregation without group by work fine');
    }
    
    public static void soqlAggregateWithGroupByIssue(){
        Integer nbRecords = [select reason from case group by reason].size();
        system.debug('nb records retrieved : '+nbRecords);
        system.debug(Limits.getQueryRows()+'/'+Limits.getLimitQueryRows());
        system.debug('we can see here that we just have consume '+Limits.getQueryRows()+' row but we are only retrieving '+nbRecords+' records, \naggregation with group count all process records through the group by');        
    }

    public static void soqlAggregateWithGroupByThroughRest(){
        Integer nbRecords = RestApiUtil.execute('select reason from case group by reason',false).size();
        system.debug('nb records retrieved : '+nbRecords);
        system.debug(Limits.getQueryRows()+'/'+Limits.getLimitQueryRows());
        system.debug('we can see here that we just have consume '+Limits.getQueryRows()+' row but we are retrieving '+nbRecords+' records, \naggregation with group count all process records through the group by');
    }

    public static void CalloutBeforeDML(){
        // CallOut operation after DML . Avoid this
        Integer nbRecords = RestApiUtil.execute('select reason from case group by reason',false).size();
        system.debug('nb records retrieved : '+nbRecords);        
        // DML Operation
        insert (new Case (reason='test5'));
    }

    
    public static void CalloutAfterDMLNotWorking(){
        // DML Operation
        insert (new Case (reason='test4'));
        // CallOut operation after DML . Avoid this
        Integer nbRecords = RestApiUtil.execute('select reason from case group by reason',false).size();
        system.debug('nb records retrieved : '+nbRecords);        
    }
    
    public static void CalloutAfterDMLThroughRest(){
        // DML Operation
        RestApiUtil.restUpsert(new Case (reason='test6'));
        //insert (new Case (reason='test4'));
        // CallOut operation after DML . Avoid this
        Integer nbRecords = RestApiUtil.execute('select reason from case group by reason',false).size();        
        system.debug('nb records retrieved : '+nbRecords);        
    }
    

}
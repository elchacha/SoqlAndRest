# SoqlAndRest
Show how you can use RestApi to help apex to work with code limits

## Step 1 : First install or create the class within the repository
```apex
//Step 1 : create data if needed in a scratch org or a dedicated sandbox 
List<Case> cases = new List<Case>();
for(integer i=0;i<10;i++){
	cases.add(new Case (reason='test1'));
	cases.add(new Case (reason='test2'));
	cases.add(new Case (reason='test3'));
}
insert cases;
```


## Step 2 : execute the below code and display only the debug log information. this use case show that everything work as expected
### RestSoqlExamples.soqlAggregateWorkFine();
```apex
system.debug([select count() from case ]);
system.debug(Limits.getQueryRows()+'/'+getLimitQueryRows());
system.debug('we can see here that we just have consume 1 row , aggregation without group by work fine');
```
### Expected results :
- executing : [select count() from case ]
- found records : 37
- limits found : 1/50000
- we can see here that we just have consume 1 row , aggregation without group by work fine

## Step 3 : execute the below code and display only the debug log information.This use case show that using group by is consuming "too many rows" , it can become an issue while in production if there is too many records to process
### RestSoqlExamples.soqlAggregateWithGroupByIssue();
```apex
Integer nbRecords = [select reason from case group by reason].size();
system.debug('nb records retrieved : '+nbRecords);
system.debug(Limits.getQueryRows()+'/'+Limits.getLimitQueryRows());
system.debug('we can see here that we just have consume '+Limits.getQueryRows()+' row but we are only retrieving '+nbRecords+' records, \naggregation with group count all process records through the group by');        
```
### Expected results :
- nb records retrieved : 8
- 37/50000
- we can see here that we just have consume 37 row but we are only retrieving 8 records, 
- aggregation with group count all process records through the group by


## Step 4 : execute the following code and display only the debug log information.This use case show that using a rest operation to retrieve information is reducing the number of consumed rows
### RestSoqlExamples.soqlAggregateWithGroupByThroughRest();
```apex
Integer nbRecords = RestApiUtil.execute('select reason from case group by reason',false).size();
system.debug('nb records retrieved : '+nbRecords);
system.debug(Limits.getQueryRows()+'/'+Limits.getLimitQueryRows());
system.debug('we can see here that we just have consume '+Limits.getQueryRows()+' row but we are retrieving '+nbRecords+' records, aggregation with group count all process records through the group by');
```
### Expected results :
- nb records retrieved : 6
- 0/50000
- we can see here that we just have consume 0 row but we are retrieving 6 records, 
- aggregation with group count all process records through the group by

## Step 5 : WARNING. Callout operation should be done prior to any dml operation. The below code will **NOT** work
### RestSoqlExamples.CalloutAfterDMLNotWorking();
- // DML Operation
- insert (new Case (reason='test4'));
- // CallOut operation after DML . Avoid this
- Integer nbRecords = RestApiUtil.execute('select reason from case group by reason',false).size();
- system.debug('nb records retrieved : '+nbRecords);
### Expected results :
- Class.RestApiUtil.execute: line 18, column 1
- Class.RestSoqlExamples.CalloutAfterDMLNotWorking: line 47, column 1
- AnonymousBlock: line 1, column 1

## Step 6 : WARNING. Callout operation should be done prior to any dml operation. The below code will **NOW** work
### RestSoqlExamples.CalloutBeforeDML();
- // CallOut operation before DML . All is good
- Integer nbRecords = RestApiUtil.execute('select reason from case group by reason',false).size();
- system.debug('nb records retrieved : '+nbRecords);
- // DML Operation
- insert (new Case (reason='test5'));
### Expected results :
- nb records retrieved : 7


## Step 7 : WARNING. Callout operation should be done prior to any dml operation. The below code will work but we are the transaction rollback in case of error
### RestSoqlExamples.CalloutAfterDMLThroughRest();
- // DML Operation
- RestApiUtil.restUpsert(new Case (reason='test6'));
- //insert (new Case (reason='test4'));
- // CallOut operation after DML . Avoid this
- Integer nbRecords = RestApiUtil.execute('select reason from case group by reason',false).size();
### Expected results :
- restUpsertEndpoint > https://fcha.my.salesforce.com/services/data/v47.0/sobjects/Case
- body>{"attributes":{"type":"Case"},"Reason":"test6"}
- 201
- {"id":"5001j000006AKV8AAO","success":true,"errors":[]}
- nb records retrieved : 8


system.debug('nb records retrieved : '+nbRecords);

@isTest
public class Test_ScriptBatch {
    @isTest
    public static void testPass(){
        scriptBatch myBatchObject = new scriptBatch(); 
        Id batchId = Database.executeBatch(myBatchObject,1);
        scriptBatch.testPass();
    }
}
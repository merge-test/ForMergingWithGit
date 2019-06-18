@isTest
public class Test_MapperClass {
    
    @isTest public static void Test1()
    {
        MapperClass ap1 = new MapperClass();   
       
        ap1.saveMapping();
        ap1.updateAccList();
        ap1.updateOppList();
        ap1.deleteRecord();
    }
}
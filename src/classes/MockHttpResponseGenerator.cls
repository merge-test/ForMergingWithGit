@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
       
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        if(req.getEndpoint()=='http://test.com/test/sendCustomer')
        {
            res.setBody('{"Customer": {'+
                        '"Id":"1"}}');
        }
        else if(req.getEndpoint()=='http://test.com/test/updateCustomer')
        {
            res.setBody('{"Customer": {'+
                        '"Id":"1"}}');
        }
        else if(req.getEndpoint()=='http://test.com/test/sendInvoice')
        {
            res.setBody('{"Invoice": {'+
                        '"Id":"1",'+
                        '"TotalAmt":100,'+
                        '"DueDate":"2018-09-24"'+
                        '}}');
        }
        else if(req.getEndpoint()=='http://test.com/test/refreshtoken')
        {
            res.setBody('{"access_token":"456",'+
                        '"refresh_token":"123"}');
        }
        else if(req.getEndpoint()=='http://test.com/test/getCustomerSyncToken')
        {
            res.setBody('{'+
                        '"QueryResponse": {'+
                        '"Customer": ['+
                        '{'+
                        '"Id": "1",'+
                        '"SyncToken": "1"}'+
                        ']'+
                        '}'+
                        '}');
        }
        else if(req.getEndpoint()=='http://test.com/test/getCustomer')
        {
            res.setBody('{'+
                        '"QueryResponse": {'+
                        '"Customer": ['+
                        '{'+
                        '"Id": "1",'+
                        '"SyncToken": "1",'+
                        '"FamilyName": "Test"}'+
                        ']'+
                        '}'+
                        '}');
        }
        else if(req.getEndpoint()=='http://test.com/test/getInvoice')
        {
            res.setBody('{'+
                        '"QueryResponse": {'+
                        '"Invoice": ['+
                        '{'+
                        '"Id": "1",'+
                        '"SyncToken": "1",'+
                        '"TotalAmt":100,'+
                        '"DueDate":"2018-09-24",'+
                        ' "Line": [{'+
                        '  "Amount": 0.0,'+
                        '  "Description": "Schematic Design"'+
                        '  }]'+
                        ' }'+
                        ']'+
                        '}'+
                        '}');
        }
        
        if(req.getHeader('Authorization')=='Bearer 456' || req.getEndpoint()=='http://test.com/test/refreshtoken')
        {
            res.setStatusCode(200);
        }
        else
        {
            res.setStatusCode(401);
        }


        return res;
    }
}
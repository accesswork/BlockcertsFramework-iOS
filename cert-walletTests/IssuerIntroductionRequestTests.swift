//
//  IssuerIntroductionRequestTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/2/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest

class IssuerIntroductionRequestTests: XCTestCase {
    func testSuccessfulIntroductionRequest() {
        let itShouldCallTheCallback = expectation(description: "The request's callback handler will be called.")
        let itShouldCallTheServer = expectation(description: "Mocking framework should call our fake server function.")
        
        let expectedAddress = "FakeRecipientPublicKey"
        let expectedEmail = "johnny@blockcerts.org"
        let expectedFirstName = "Johnny"
        let expectedLastName = "Strong"
        
        let issuer = Issuer(name: "BlockCerts Issuer",
                            email: "issuer@blockcerts.org",
                            image: "data:image/png;base64,".data(using: .utf8)!,
                            id: URL(string: "https://blockcerts.org/issuer.json")!,
                            url: URL(string: "https://blockcerts.org")!,
                            publicIssuerKeys: [
                                KeyRotation(on: Date(timeIntervalSince1970: 0), key: "FAKE_ISSUER_KEY")
                            ],
                            publicRevocationKeys: [
                                KeyRotation(on: Date(timeIntervalSince1970: 0), key: "FAKE_REVOCATION_KEY")
                            ],
                            introductionURL: URL(string: "https://blockcerts.org/introduce/")!)

        let recipient = Recipient(givenName: expectedFirstName,
                                  familyName: expectedLastName,
                                  identity: expectedEmail,
                                  identityType: "email",
                                  isHashed: false,
                                  publicAddress: expectedAddress,
                                  revocationAddress: nil)
        
        // Mock out the network
        let session = MockURLSession()
        let url = issuer.introductionURL!
        session.respond(to: url) { request in
            let body = request.httpBody
            XCTAssertNotNil(body, "Request to the issuer should have a body.")
            
            let json = try? JSONSerialization.jsonObject(with: body!, options: [])
            XCTAssertNotNil(json, "Body of the request should be parsable as json")
            
            let map = json as? [String: String]
            XCTAssertNotNil(map, "Currently, the json is always String:String type")
            
            XCTAssertEqual(map!["bitcoinAddress"], expectedAddress)
            XCTAssertEqual(map!["email"], expectedEmail)
            XCTAssertEqual(map!["firstName"], expectedFirstName)
            XCTAssertEqual(map!["lastName"], expectedLastName)

            itShouldCallTheServer.fulfill()
            return (
                data: "Success".data(using: .utf8),
                response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
                error: nil
            )
        }
        
        // Create the request
        let request = IssuerIntroductionRequest(introduce: recipient, to: issuer, session: session) { (success, error) in
            
            XCTAssertTrue(success)
            XCTAssertNil(error)
            itShouldCallTheCallback.fulfill()
        }
        request.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)

    }
}

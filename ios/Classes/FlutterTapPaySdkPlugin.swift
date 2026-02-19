// ios/Classes/FlutterTapPaySdkPlugin.swift
import Flutter
import UIKit
import TPDirect

public class FlutterTapPaySdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_tappay_sdk", binaryMessenger: registrar.messenger())
    let instance = FlutterTapPaySdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]

    switch call.method {
    case "sdkVersion":
      result(TPDSetup.getVersion())

    case "initPayment":
      let appId = args?["appId"] as? Int
      let appKey = args?["appKey"] as? String
      let isSandbox = args?["isSandbox"] as? Bool ?? false

      initTapPay(appId: appId, appKey: appKey, isSandbox: isSandbox) { res in
        result(res)
      }

    case "isValidCard":
      let cardNumber = args?["cardNumber"] as? String
      let mm = args?["mm"] as? String
      let yy = args?["yy"] as? String
      let cvv = args?["cvv"] as? String
      let ok = validateCard(cardNumber: cardNumber, expiryMonth: mm, expiryYear: yy, cvv: cvv)
      result(ok)

    case "getPrimeByCardInfo":
      let cardNumber = args?["cardNumber"] as? String
      let mm = args?["mm"] as? String
      let yy = args?["yy"] as? String
      let cvv = args?["cvv"] as? String
      let cardholder = args?["cardholder"] as? [String:Any]

      createTokenByCardInfo(cardNumber: cardNumber, expiryMonth: mm, expiryYear: yy, cvv: cvv, cardholder: cardholder) { res in
        result(res)
      }

    case "getCardholderInfoPrime":
      // Native iOS: we currently expect card info to generate prime.
      // If you require iOS to support a different flow (e.g., a specific SDK call to return cardholder prime),
      // implement it here. For now we return an informative response, instructing to use getPrimeByCardInfo.
      let response: [String: Any?] = [
        "success": false,
        "status": nil,
        "message": "getCardholderInfoPrime is not implemented on iOS without card info. Use getCardPrime with cardholder parameter.",
        "prime": nil,
        "cardholder": nil
      ]
      result(response)

    case "initGooglePay":
      // Not implemented on iOS (Google Pay is Android-only)
      let res: [String: Any?] = [
        "success": false,
        "message": "Google Pay is only available on Android."
      ]
      result(res)

    case "requestGooglePay":
      let res: [String: Any?] = [
        "success": false,
        "message": "Google Pay is only available on Android."
      ]
      result(res)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Init TapPay
  private func initTapPay(appId: Int?, appKey: String?, isSandbox: Bool, onResult: @escaping ([String:Any?]) -> Void) {
    guard let appId = appId, let appKey = appKey else {
      onResult(["success": false, "message": "\"appId\" and \"appKey\" are required."])
      return
    }

    let serverType: TPDServerType = isSandbox ? .sandbox : .production
    // TPDSetup init
    TPDSetup.initInstance(withAppId: Int32(appId), withAppKey: appKey, with: serverType)

    onResult(["success": true, "message": nil])
  }

  // MARK: - Validate Card
  private func validateCard(cardNumber: String?, expiryMonth: String?, expiryYear: String?, cvv: String?) -> Bool {
    guard let cardNumber = cardNumber, let mm = expiryMonth, let yy = expiryYear, let cvv = cvv else {
      return false
    }
    // TPDCard.validate returns TPDCardValidationResult on iOS
    let validation = TPDCard.validate(with: cardNumber, withDueMonth: mm, withDueYear: yy, withCCV: cvv)
    return (validation?.isCardNumberValid ?? false) && (validation?.isExpiryDateValid ?? false) && (validation?.isCCVValid ?? false)
  }

  // MARK: - Create Token by Card Info (getPrimeByCardInfo)
  private func createTokenByCardInfo(cardNumber: String?, expiryMonth: String?, expiryYear: String?, cvv: String?, cardholder: [String:Any]?, onResult: @escaping ([String:Any?]) -> Void) {
    guard let cardNumber = cardNumber, let expiryMonth = expiryMonth, let expiryYear = expiryYear, let cvv = cvv else {
      let res = CreateCardTokenByCardInfoResult(success: false, status: nil, message: "Missing required parameters for \"getPrimeByCardInfo\" method.", prime: nil)
      onResult(res.toDictionary())
      return
    }

    // Use TapPay iOS SDK to set card and generate prime
    // According to TapPay iOS SDK (TPDCard.setWithCardNumber(...) with callbacks)
    TPDCard.setWithCardNumber(cardNumber, withDueMonth: expiryMonth, withDueYear: expiryYear, withCCV: cvv)
      .onSuccessCallback({ (prime: String!, cardInfo: TPDCardInfo!) in
        var result = CreateCardTokenByCardInfoResult(success: true, status: nil, message: nil, prime: prime).toDictionary()
        if let ch = cardholder {
          // echo provided cardholder back to Dart so server can use it
          result["cardholder"] = ch
        } else {
          // if cardInfo contains cardholder data, you may extract it here; left as TODO
        }
        onResult(result)
      })
      .onFailureCallback({ (status: NSNumber!, message: String!) in
        let res = CreateCardTokenByCardInfoResult(success: false, status: status.intValue, message: message, prime: nil)
        onResult(res.toDictionary())
      })
  }
}

// MARK: - Helper: CreateCardTokenByCardInfoResult for Swift
// Implement a small struct similar to the Android/iOS model used in your repo.
// If you already have CreateCardTokenByCardInfoResult.swift in ios/Classes/models, use it and remove this helper.
public struct CreateCardTokenByCardInfoResult {
  public var success: Bool
  public var status: Int?
  public var message: String?
  public var prime: String?

  public func toDictionary() -> [String: Any?] {
    return [
      "success": success,
      "status": status,
      "message": message,
      "prime": prime
    ]
  }
}


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
      // NOTE: If your TPDirect SDK provides a different API for fetching the SDK version,
      // replace this call with that API. Some TPDirect versions do not expose getVersion().
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

    // NOTE:
    // The TPDirect SDK has had breaking changes across versions. The code below uses
    // the commonly-seen initialization API (initInstance with server type enum).
    // If your TPDirect version uses a different initializer or enum naming, replace
    // the call below with the correct API (or pin the TPDirect pod to a compatible version).
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
    // Use the parameter label that recent TPDirect SDKs expect.
    let validation = TPDCard.validate(withCardNumber: cardNumber, withDueMonth: mm, withDueYear: yy, withCCV: cvv)
    return (validation?.isCardNumberValid ?? false) && (validation?.isExpiryDateValid ?? false) && (validation?.isCCVValid ?? false)
  }

  // MARK: - Create Token by Card Info (getPrimeByCardInfo)
  private func createTokenByCardInfo(cardNumber: String?, expiryMonth: String?, expiryYear: String?, cvv: String?, cardholder: [String:Any]?, onResult: @escaping ([String:Any?]) -> Void) {
    guard let cardNumber = cardNumber, let expiryMonth = expiryMonth, let expiryYear = expiryYear, let cvv = cvv else {
      let res = CreateCardTokenByCardInfoResult(success: false, status: nil, message: "Missing required parameters for \"getPrimeByCardInfo\" method.", prime: nil)
      onResult(res.toDictionary())
      return
    }

    // If the SDK provides a direct API to set cardholder info, you should call it here
    // before requesting the prime. Example (pseudocode):
    //
    // if let ch = cardholder {
    //   TPDCard.setCardholder(phone: ch["phone_number"] as? String,
    //                         email: ch["email"] as? String,
    //                         nameEn: ch["name_en"] as? String,
    //                         countryCode: ch["phone_number_country_code"] as? String)
    // }

    // Use TapPay iOS SDK to set card and generate prime.
    // The onSuccess/onFailure signatures vary between SDK versions; here we use a
    // 4-argument success callback and (Int, String) failure callback which matches
    // recent SDK expectations.
    TPDCard.setWithCardNumber(cardNumber, withDueMonth: expiryMonth, withDueYear: expiryYear, withCCV: cvv)
      .onSuccessCallback({ (prime: String?, cardInfo: TPDCardInfo?, someString: String?, extraInfo: [AnyHashable: Any]?) in
        var result = CreateCardTokenByCardInfoResult(success: true, status: nil, message: nil, prime: prime).toDictionary()
        if let ch = cardholder {
          // echo provided cardholder back to Dart so server can use it
          result["cardholder"] = ch
        } else {
          // if cardInfo contains cardholder data, you may extract it here; left as TODO
        }
        onResult(result)
      })
      .onFailureCallback({ (status: Int, message: String) in
        let res = CreateCardTokenByCardInfoResult(success: false, status: status, message: message, prime: nil)
        onResult(res.toDictionary())
      })
  }
}

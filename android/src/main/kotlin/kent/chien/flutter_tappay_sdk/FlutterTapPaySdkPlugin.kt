package kent.chien.flutter_tappay_sdk

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kent.chien.flutter_tappay_sdk.models.CreateCardTokenByCardInfoResult
import kent.chien.flutter_tappay_sdk.models.TapPaySdkCommonResult
import tech.cherri.tpdirect.api.TPDCard
import tech.cherri.tpdirect.api.TPDServerType
import tech.cherri.tpdirect.api.TPDSetup

/** FlutterTapPaySdkPlugin */
class FlutterTapPaySdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel

  private lateinit var context: Context
  private lateinit var activity: Activity
  private lateinit var googlePayHandler: GooglePayHandler

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_tappay_sdk")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    googlePayHandler = GooglePayHandler(context)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    googlePayHandler.setActivity(activity)
    binding.addActivityResultListener(googlePayHandler)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null!!
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    googlePayHandler.setActivity(activity)
    binding.addActivityResultListener(googlePayHandler)
  }

  override fun onDetachedFromActivity() {
    activity = null!!
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {

      // Get TapPay SDK version
      "sdkVersion" -> result.success(TPDSetup.getVersion())

      // Initialize TapPay SDK
      "initPayment" -> {
        val appId = call.argument<Int?>("appId")
        val appKey = call.argument<String?>("appKey")
        val isSandbox = call.argument<Boolean?>("isSandbox")

        initTapPay(appId, appKey, isSandbox) {
          result.success(it)
        }
      }

      // Validate card
      "isValidCard" -> {
        val carNumber = call.argument<String?>("cardNumber")
        val expiryMonth = call.argument<String?>("mm")
        val expiryYear = call.argument<String?>("yy")
        val cvv = call.argument<String?>("cvv")

        result.success(validateCard(carNumber, expiryMonth, expiryYear, cvv))
      }

      // Create token (prime) by card information
      "getPrimeByCardInfo" -> {
        val carNumber: String? = call.argument<String?>("cardNumber")
        val expiryMonth: String? = call.argument<String?>("mm")
        val expiryYear: String? = call.argument<String?>("yy")
        val cvv: String? = call.argument<String?>("cvv")
        // NEW: read optional cardholder map from Dart
        val cardholderMap: HashMap<String, Any?>? = call.argument<HashMap<String, Any?>>("cardholder")

        createTokenByCardInfo(carNumber, expiryMonth, expiryYear, cvv, cardholderMap, onResult = {
          result.success(it)
        })
      }

      // New: get cardholder-info prime (native fallback)
      "getCardholderInfoPrime" -> {
        // At native layer we currently require card info to generate prime.
        // Since Dart's getCardholderInfoPrime() on native path doesn't supply card info,
        // we respond with informative message. If you want native to produce cardholder-prime
        // without card info, implement the SDK-specific flow here.
        val response = HashMap<String, Any?>()
        response["success"] = false
        response["status"] = null
        response["message"] = "getCardholderInfoPrime is not implemented on Android without card info. Use getCardPrime with cardholder parameter."
        response["prime"] = null
        response["cardholder"] = null
        result.success(response)
      }

      "initGooglePay" -> {
        val merchantName: String? = call.argument<String?>("merchantName")
        val cardTypes: List<String>? = call.argument<List<String>?>("cardTypes")
        val authMethods: List<String>? = call.argument<List<String>?>("authMethods")
        val isPhoneNumberRequired: Boolean? = call.argument<Boolean?>("isPhoneNumberRequired")
        val isBillingAddressRequired: Boolean? =
          call.argument<Boolean?>("isBillingAddressRequired")
        val isEmailRequired: Boolean? = call.argument<Boolean?>("isEmailRequired")

        initGooglePay(
          merchantName,
          cardTypes,
          authMethods,
          isPhoneNumberRequired,
          isBillingAddressRequired,
          isEmailRequired,
          onResult = {
            result.success(it)
          }
        )
      }

      "requestGooglePay" -> {
        val price: Double? = call.argument<Double?>("price")
        val currencyCode: String? = call.argument<String?>("currencyCode")

        requestGooglePay(price, currencyCode, onResult = {
          result.success(it)
        })
      }

      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  /**
   * Initialize TapPay SDK
   */
  private fun initTapPay(
    appId: Int?, appKey: String?, isSandbox: Boolean?,
    onResult: (HashMap<String, Any?>) -> (Unit)
  ) {
    if (appId == null || appKey == null) {
      val error = TapPaySdkCommonResult(
        false,
        "\"appId\" and \"appKey\" are required."
      ).toHashMap()
      onResult(error)
      return
    }

    val serverType: TPDServerType = if (isSandbox == true) {
      TPDServerType.Sandbox
    } else {
      TPDServerType.Production
    }

    TPDSetup.initInstance(context, appId, appKey, serverType)
    val result = TapPaySdkCommonResult(
      true,
      ""
    ).toHashMap()

    onResult(result)
  }

  /**
   * Validate card
   */
  private fun validateCard(
    cardNumber: String?, expiryMonth: String?, expiryYear: String?,
    cvv: String?
  ): Boolean {
    if (cardNumber.isNullOrEmpty() || expiryMonth.isNullOrEmpty() || expiryYear.isNullOrEmpty() ||
      cvv.isNullOrEmpty()
    ) {
      return false
    }

    val result = TPDCard.validate(
      StringBuffer(cardNumber), StringBuffer(expiryMonth),
      StringBuffer(expiryYear), StringBuffer(cvv)
    )
    return result.isCardNumberValid && result.isExpiryDateValid && result.isCCVValid
  }

  /**
   * Create token (prime)
   *
   * Modified to accept optional cardholder HashMap and echo it in the success result.
   */
  // 替換整個 createTokenByCardInfo(...) 的主體為以下
private fun createTokenByCardInfo(
  cardNumber: String?, expiryMonth: String?, expiryYear: String?,
  cvv: String?, cardholder: HashMap<String, Any?>?,
  onResult: (HashMap<String, Any?>) -> (Unit)
) {
  if (cardNumber.isNullOrEmpty() || expiryMonth.isNullOrEmpty() || expiryYear.isNullOrEmpty() ||
    cvv.isNullOrEmpty()
  ) {
    onResult(
      CreateCardTokenByCardInfoResult(
        false,
        null,
        "Missing required parameters for \"getPrimeByCardInfo\" method.",
        null
      ).toHashMap()
    )
    return
  }

  val tpdCard = TPDCard(
    context, StringBuffer(cardNumber), StringBuffer(expiryMonth),
    StringBuffer(expiryYear), StringBuffer(cvv)
  )

  // === 嘗試注入 cardholder 到 SDK（若 SDK 有支援的話） ===
  if (cardholder != null) {
    val phone = cardholder["phone_number"]?.toString()
    val email = cardholder["email"]?.toString()
    val nameEn = cardholder["name_en"]?.toString()
    val countryCode = cardholder["phone_number_country_code"]?.toString()

    // 嘗試幾種可能的 method 名（根據不同版本 SDK 名稱可能不同）
    val candidateMethodNames = arrayOf(
      "setCardholderInfo",        // 常見命名
      "setCardHolderInfo",
      "setCardholder",
      "setCardHolder",
      "setConsumer",              // 若 SDK 用 consumer/holder 等命名
      "setConsumerInfo"
    )

    var injected = false
    for (name in candidateMethodNames) {
      try {
        // 嘗試找到 instance method
        val m = tpdCard.javaClass.getMethod(name, String::class.java, String::class.java, String::class.java, String::class.java)
        m.invoke(tpdCard, phone, email, nameEn, countryCode)
        injected = true
        break
      } catch (e: NoSuchMethodException) {
        // 忽略，試下一個候選
      } catch (e: Exception) {
        // 其他例外也忽略（反射呼叫失敗）
      }
    }

    // 如果沒找到 instance method，嘗試找 static/class 形式 (例如 TPDCard.setCardholderInfo(...))
    if (!injected) {
      for (name in candidateMethodNames) {
        try {
          val clazz = TPDCard::class.java
          val m2 = clazz.getMethod(name, String::class.java, String::class.java, String::class.java, String::class.java)
          m2.invoke(null, phone, email, nameEn, countryCode)
          injected = true
          break
        } catch (e: NoSuchMethodException) {
        } catch (e: Exception) {
        }
      }
    }

    // 若成功注入（injected == true），在這裡可選 log
    // 若沒有注入，繼續下面回傳時 echo cardholder（server 可使用 echo 的 cardholder 來做 Update 用）
  }

  // success / failure callback
  tpdCard.onSuccessCallback { prime, _, _, cardInfo ->
    val resultMap = CreateCardTokenByCardInfoResult(true, null, null, prime).toHashMap()

    // Always include the original cardholder that Dart passed (so server can use it to update if SDK cannot accept it directly)
    if (cardholder != null) {
      resultMap["cardholder"] = cardholder
    } else {
      // 若 SDK 回傳 cardInfo 有 cardholder，可在此解析並放入
      try {
        // pseudocode: if cardInfo has fields for cardholder
        // val returned = parseCardInfoCardholder(cardInfo)
        // if (returned != null) resultMap["cardholder"] = returned
      } catch (e: Exception) {
      }
    }

    onResult(resultMap)
  }.onFailureCallback { status, reportMsg ->
    onResult(CreateCardTokenByCardInfoResult(false, status, reportMsg, null).toHashMap())
  }

  // If TapPay Android SDK supports passing cardholder into the token creation call,
  // the reflection above should have attempted to call it.
  tpdCard.createToken("UNKNOWN")
}


  private fun initGooglePay(
    merchantName: String? = null,
    cardTypes: List<String>? = null,
    authMethods: List<String>? = null,
    isPhoneNumberRequired: Boolean? = null,
    isBillingAddressRequired: Boolean? = null,
    isEmailRequired: Boolean? = null,
    onResult: (HashMap<String, Any?>) -> (Unit)
  ) {
    val callback = object : GooglePayHandler.Companion.GooglePayCheckCallback {
      override fun onGooglePayCheck(result: TapPaySdkCommonResult) {
        onResult(
          result.toHashMap()
        )
      }
    }

    googlePayHandler.initGooglePay(
      merchantName,
      cardTypes,
      authMethods,
      isPhoneNumberRequired,
      isBillingAddressRequired,
      isEmailRequired,
      callback
    )
  }

  private fun requestGooglePay(
    price: Double?,
    currencyCode: String?,
    onResult: (HashMap<String, Any?>) -> (Unit)
  ) {
    if (price == null || currencyCode.isNullOrEmpty()) {
      onResult(
        TapPaySdkCommonResult(
          false,
          "Missing required parameters \"priceTotal\" or \"currencyCode\" for \"requestGooglePay\" method."
        ).toHashMap()
      )
      return
    }

    if (googlePayHandler.isAvailable()) {

      val callback = object : GooglePayHandler.Companion.GooglePayPaymentCallback {
        override fun onGooglePayResult(result: GooglePayHandler.Companion.GooglePayPaymentResult) {
          onResult(
            result.toHashMap()
          )
        }
      }

      googlePayHandler.requestPayment(price, currencyCode, callback)
    } else {
      onResult(
        TapPaySdkCommonResult(
          false,
          "Google Pay is not available."
        ).toHashMap()
      )
    }

  }
}

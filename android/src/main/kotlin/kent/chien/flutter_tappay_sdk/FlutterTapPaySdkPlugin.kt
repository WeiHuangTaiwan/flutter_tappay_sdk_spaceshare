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

  // Make activity nullable — safer for detach/reattach cycles
  private var activity: Activity? = null

  private lateinit var googlePayHandler: GooglePayHandler

  // Keep a reference to ActivityPluginBinding so we can remove listeners on detach
  private var activityPluginBinding: ActivityPluginBinding? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_tappay_sdk")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    googlePayHandler = GooglePayHandler(context)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityPluginBinding = binding
    // googlePayHandler expects a non-null Activity; only set when available
    activity?.let {
      googlePayHandler.setActivity(it)
    }
    binding.addActivityResultListener(googlePayHandler)
    // If googlePayHandler needs permission callbacks, you can also add:
    // binding.addRequestPermissionsResultListener(googlePayHandler)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    // remove previously registered listeners and clear activity/binding references
    try {
      activityPluginBinding?.removeActivityResultListener(googlePayHandler)
      // If you registered request permissions listener, remove it similarly:
      // activityPluginBinding?.removeRequestPermissionsResultListener(googlePayHandler)
    } catch (e: Exception) {
      // ignore if removal isn't supported in some older embedding versions
    }
    activity = null
    activityPluginBinding = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityPluginBinding = binding
    activity?.let {
      googlePayHandler.setActivity(it)
    }
    binding.addActivityResultListener(googlePayHandler)
    // binding.addRequestPermissionsResultListener(googlePayHandler)
  }

  override fun onDetachedFromActivity() {
    try {
      activityPluginBinding?.removeActivityResultListener(googlePayHandler)
      // activityPluginBinding?.removeRequestPermissionsResultListener(googlePayHandler)
    } catch (e: Exception) {
    }
    activity = null
    activityPluginBinding = null
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
   * It also attempts to inject cardholder into the TPDCard/SDK via reflection for
   * common method names if the official SDK exposes such APIs.
   */
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

    // === Attempt to inject cardholder into SDK via reflection (if SDK exposes such API) ===
    if (cardholder != null) {
      val phone = cardholder["phone_number"]?.toString()
      val email = cardholder["email"]?.toString()
      val nameEn = cardholder["name_en"]?.toString()
      val countryCode = cardholder["phone_number_country_code"]?.toString()

      // Candidate method names (common patterns). If TapPay SDK provides a formal API,
      // replace this reflection code with direct API calls to the SDK.
      val candidateMethodNames = arrayOf(
        "setCardholderInfo",
        "setCardHolderInfo",
        "setCardholder",
        "setCardHolder",
        "setConsumer",
        "setConsumerInfo"
      )

      var injected = false
      for (name in candidateMethodNames) {
        try {
          val m = tpdCard.javaClass.getMethod(name, String::class.java, String::class.java, String::class.java, String::class.java)
          m.invoke(tpdCard, phone, email, nameEn, countryCode)
          injected = true
          break
        } catch (e: NoSuchMethodException) {
          // not found, try next candidate
        } catch (e: Exception) {
          // ignore other exceptions
        }
      }

      // Try static/class method variants
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

      // If injected == true, we've attempted to set cardholder in SDK.
      // If not, we will still echo the cardholder in the result map so the server can perform an update.
    }

    tpdCard.onSuccessCallback { prime, _, _, cardInfo ->
      val resultMap = CreateCardTokenByCardInfoResult(true, null, null, prime).toHashMap()

      // Echo the original cardholder to result so server can use it if SDK couldn't accept it
      if (cardholder != null) {
        resultMap["cardholder"] = cardholder
      } else {
        // If SDK returns cardInfo containing cardholder fields, parse and include them here.
        try {
          // TODO: parse cardInfo if it contains cardholder data
        } catch (e: Exception) {
        }
      }

      onResult(resultMap)
    }.onFailureCallback { status, reportMsg ->
      onResult(CreateCardTokenByCardInfoResult(false, status, reportMsg, null).toHashMap())
    }

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

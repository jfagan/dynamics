module Dynamics
  class Payment
    attr_accessor :ets_payment_obj

    def initialize(ets_payment_obj = nil)
      @ets_payment_obj = ets_payment_obj

      @customer_code = ets_payment_obj.client_code
      @api_endpoint = ENV["ETS_DYNAMICS_API"] + "/api/payment/"

      #TODO Delete this functionality soon after go live, crude logging solution for debugging.
      @api_log = DynamicsApiLog.new ({client_code: @customer_code,
                                     user_pid: ets_payment_obj.user_pid,
                                     order_id: ets_payment_obj.order.id}
                                     )
      @api_log.save
    end

    def perform
      post_payment
    end

    def destroy_failed_jobs?
      false
    end

    def as_json
      { "custid": ets_payment_obj.client_code,
        "refnbr": ets_payment_obj.order.number,
        "amount": ets_payment_obj.amount,
        "invoices": ets_payment_obj.order.line_items.where(doc_type: 'Invoice').map(&:invoice_number),
        "finance_charges": ets_payment_obj.order.line_items.where(doc_type: 'Finance Charge').map(&:invoice_number),
        "batch_type": ets_payment_obj.order.frequency,
        "notes": {
          "trans_number": ets_payment_obj.transaction_number,
          "user_id": ets_payment_obj.user_pid,
          "user_name": "#{ets_payment_obj.order.user.firstname} #{ets_payment_obj.order.user.lastname}",
          "receipt_email": ets_payment_obj.gateway_response[:billing][:email],
          "gateway_name": "PayJunction",
          "payment_source": {
            "object": map_web_to_dynamics_object_type(ets_payment_obj.gateway_response[:vault][:type]),
            "brand": ets_payment_obj.gateway_response[:vault][:accountType],
            "expiry_month": "",
            "expiry_year": "",
            "last4": ets_payment_obj.gateway_response[:vault][:lastFour]
          }
        }
      }
    end

    def map_web_to_dynamics_object_type(payment_type)
      payment_type.upcase == "ACH" ? "ACH" : "Credit Card"
    end

    def post_payment
      begin
        request(@api_endpoint, as_json)
      rescue Exception => e
        raise e
      end
    end

    def success
      ets_payment_obj.order.is_erp_sync_completed = true
      ets_payment_obj.order.sync_completed_at = DateTime.now
      ets_payment_obj.order.save

      @api_log.result = "success"
      @api_log.save
    end

    def failure(job)
      @api_log.result = "failure"
      @api_log.error = job.last_error
      @api_log.save
    end

    def error(job, exception)
      @api_log.result = "error"
      @api_log.last_error = exception.to_s + job.last_error.to_s
      @api_log.save
    end

    def request_headers
      {'Content-Type': 'application/json',
       'Accept': 'application/json'}
    end

    def request(url, payload)
      payload = payload.to_json
      @api_log.endpoint = url
      @api_log.request_headers = request_headers
      @api_log.request_payload = payload
      @api_log.save

      #TODO Uncomment this line for testing / production, no Dynamics demo environment
      response = RestClient.post(url, payload, request_headers)

      @api_log.response_code = response.code
      @api_log.response_headers = response.headers
      @api_log.response_payload = response.body
      @api_log.save

      response
     end

  end
end

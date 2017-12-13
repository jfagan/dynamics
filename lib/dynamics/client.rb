module Dynamics
  class Client
    attr_reader :api_token, :company_id, :site_id, :customer_code, :api_endpoint

    def initialize(customer_code)
      @customer_code = customer_code
      @api_endpoint = ENV["ETS_DYNAMICS_API"]

      if @customer_code.blank?
        raise ArgumentError, 'Customer Code is required'
      end
    end

    def get_invoices(params = {})
      if params[:start_date].present? && params[:end_date].present?
        from_date = CGI.escape(params[:start_date].strftime("%m/%d/%Y"))
        date_to = CGI.escape(params[:end_date].strftime("%m/%d/%Y"))
        end_point = "#{@api_endpoint}/api/clients/#{@customer_code}/invoices?date_from=#{from_date}&date_to=#{date_to}"
      else
        end_point = "#{@api_endpoint}/api/clients/#{@customer_code}/invoices"
      end

      response = request("GET", end_point, nil)
      JSON.parse(response.body).map{ |dynamics_invoice| Dynamics::Invoice.new(dynamics_invoice) }.compact
    end

    def get_invoice(invoice_number)
      end_point = "#{@api_endpoint}/api/clients/#{@customer_code}/invoices/#{invoice_number}"
      payload = {}

      response = request("GET", end_point, payload)
      Dynamics::Invoice.new(JSON.parse(response.body))
    end

    def get_statement_cycle
      end_point = "#{@api_endpoint}/api/clients/#{@customer_code}/statement_cycles"
      payload = {}

      response = request("GET", end_point, payload)
      if response.code == 200
        JSON.parse(response.body)
      else
        "Dynamics API Error: HTTP #{response.code}"
      end
    end

    def set_statement_cycle(params = {})
      end_point = "#{@api_endpoint}/api/clients/#{@customer_code}/statement_cycles"
      params[:status] = 'DISABLED' if params[:status] == 'INACTIVE'
      payload = {frequency: params[:frequency],
                 status: params[:status]}.to_json

      response = request("POST", end_point, payload)
      if response.code == 200
        get_statement_cycle
      else
        "Dynamics API Error: HTTP #{response.code}"
      end
    end

    def request_headers
      {'Content-Type': 'application/json',
       'Accept': 'application/json'}
    end

    def request(method = "POST", url, payload)
      if method == "POST"
        RestClient.post(url, payload, request_headers)
      else
        RestClient.get(url, request_headers)
      end
    end
  end
end

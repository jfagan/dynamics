module Dynamics
  class Client
    require 'thread'

    attr_reader :api_token, :company_id, :site_id, :customer_code, :api_endpoint

    def initialize(customer_code)
      @customer_code = customer_code
      @api_endpoint = ENV["ETS_DYNAMICS_API"]

      if @customer_code.blank?
        raise ArgumentError, 'Customer Code is required'
      end
    end

    def get_invoices(params = {})
      end_point = "#{@api_endpoint}/api/clients/#{@customer_code}/invoices?"
      end_point_params = init_date_filters(params)
      invoices = []

      #If a user has not defined date params, fetch all invoices for this client.
      #ETS has invoices dating back to 2013, requesting all invoices via one request is too slow (Dynamics is very slow)
      #Dividing and conquring requests into multiple, year bounded requests, running in parallel results in a far faster response time
      if end_point_params.empty?
        #=====================
        threads = []
        (2015..Date.current.year).to_a.each do |year|
          threads << Thread.new {
            thread_endpoint = end_point + ["date_from=01/01/#{year}", "date_to=12/31/#{year}"].join("&")
            instance_variable_set("@year_#{year}", request("GET", thread_endpoint, nil) )
          }
        end

        threads.each(&:join) #wait for all the threads to finish before proceeding

        (2015..Date.current.year).to_a.each do |year|
          invoices_resp = instance_variable_get("@year_#{year}")
          parsed_invoices = JSON.parse(invoices_resp.body).map{ |dynamics_invoice| Dynamics::Invoice.new(dynamics_invoice) }.compact
          invoices.push(*parsed_invoices)
        end
        #=====================
      else
        end_point = end_point + end_point_params.join("&")

        response = request("GET", end_point, nil)
        invoices = JSON.parse(response.body).map{ |dynamics_invoice| Dynamics::Invoice.new(dynamics_invoice) }.compact
      end

      invoices
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

    private

    def init_date_filters(params)
      end_point_params = []

      if params[:start_date].present? && !params[:start_date].empty?
        from_date = CGI.escape(Date.strptime(params[:start_date], "%m/%d/%Y").strftime("%m/%d/%Y"))
        end_point_params << "date_from=#{from_date}"
      end

      if params[:end_date].present? && !params[:end_date].empty?
        end_date = CGI.escape(Date.strptime(params[:end_date], "%m/%d/%Y").strftime("%m/%d/%Y"))
        end_point_params << "date_to=#{end_date}"
      end

      end_point_params
    end

  end
end

module Dynamics
  class Client
    attr_reader :api_token, :company_id, :site_id, :customer_code, :api_endpoint

    def initialize(customer_code)
      @api_token = API_KEY
      @company_id = COMPANY_ID
      @site_id = SITE_ID
      @customer_code = customer_code
      @api_endpoint = 'https://ws.etslabs.com:8899/ctDynamicsSLREST/api/'

      if @customer_code.blank? || @api_token.blank? || @company_id.blank? || @site_id.blank?
        raise ArgumentError, 'Customer Code, CompayID, SiteIT and API Auth Token are ALL required'
      end
    end

    #TODO parse param start / end dates, allow for pagination params & to display paid invoices
    def get_invoices(params = {})
      start_date = "09%2F01%2F2016"
      end_date = "12%2F30%2F2016"
      payload = {"name": "CuryDocBal", "Value": "&#33;=0"}
      end_point = "#{@api_endpoint}financial/accountsReceivable/invoiceAndMemo/query?startDocDate=#{start_date}&endDocDate=#{end_date}&custID=#{@customer_code}"

      response = request(end_point, payload)
      JSON.parse(response.body).map{ |dynamics_invoice| Dynamics::Invoice.new(dynamics_invoice) }
    end

    def get_invoice(params = {})
      end_point = "#{@api_endpoint}financial/accountsReceivable/invoiceAndMemo/#{params[:batch_number]}/#{params[:invoice_number]}"
      payload = {}

      response = request("GET", end_point, payload)
      Dynamics::Invoice.new(JSON.parse(response.body))
    end

    def request_headers
      {'Content-Type': 'application/json',
       'Accept': 'application/json',
       'Authorization': "Basic #{@api_token}",
       'CpnyID': "#{@company_id}",
       'SiteID': "#{@site_id}" }
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

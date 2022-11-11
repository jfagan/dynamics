module Dynamics
  class Invoice
    attr_accessor :order_number
    attr_accessor :paid_online
    attr_accessor :date_paid_on 

    def initialize(dynamics_json_invoice)
      @invoice = dynamics_json_invoice
    end

    def number
      @invoice["invoice_number"]
    end

    def date_issued
      DateTime.parse(@invoice["date_issued"]).strftime("%m/%d/%Y") #"2016-06-02T08:09:00"
    end
    
    def date_issued_timestamp
      DateTime.parse(@invoice["date_issued"]).strftime("%m/%d/%Y").to_time.to_i
    end

    def status=(new_status)
      @invoice["amount_due"] = (new_status == "UNPAID" ? naked_balance : "0.00")
    end

    def test_pending_status
      #if invoice is paid, return 'PENDING' otherwise return 'UNPAID'
      res = status == "UNPAID" ? status : "PENDING"

      #react testng - simulate closing a batch in Dynamics 
      #***REMOVE FOR PRODUCTION / WHEN DOING PRODUCTION TEST***
      if !date_paid_on.nil? && date_paid_on < 5.minutes.ago 
        "PAID"
      else
        res
      end 
    end

    def status
      naked_balance > 0 ? "UNPAID" : "PAID"
    end

    def total_amount
      "$%.2f" % @invoice["total_amount"]
    end

    def amount_due
      "$%.2f" % @invoice["amount_due"]
    end

    def naked_balance
      ("%.2f" % @invoice["amount_due"]).to_f
    end

    def paid_online?
      paid_online == true
    end

    def pending_amount
      ("%.2f" % @invoice["pending_amount"]).to_f
    end

    def as_json
      {
        "invoice_number": number,
           "date_issued": date_issued,
                "status": test_pending_status,
         "naked_balance": naked_balance,
          "total_amount": total_amount,
            "amount_due": amount_due,
          "order_number": order_number,
          "paid_online": paid_online?,
          "pending_amount": pending_amount
      }
    end

    private

    def parse(raw)
      JSON.parse(raw)
    end
  end
end

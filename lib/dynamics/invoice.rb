module Dynamics
  class Invoice
    attr_accessor :order_number
    attr_accessor :paid_online
    attr_accessor :date_paid_on 

    def initialize(dynamics_json_invoice)
      @invoice = dynamics_json_invoice
      @status_over_ride = nil
    end

    def number
      @invoice["invoice_number"]
    end

    def is_offline_invoice?
      #Accounting sometimes generates invoices that are not associated with a group, these "special invoices" are for services such as 
      #courier fees (cork companies) and scopion kits. These invoices only exist in the Dynamics system.
      #This is a crude implementation, we should check if the invoice number actually exists in the LIMS for a given client
      #Examples of these invoices are 'L196'
      number.length < 6
    end

    def date_issued
      DateTime.parse(@invoice["date_issued"]).strftime("%m/%d/%Y") #"2016-06-02T08:09:00"
    end
    
    def date_issued_timestamp
      DateTime.parse(@invoice["date_issued"]).strftime("%m/%d/%Y").to_time.to_i
    end

    def status=(new_status)
      @invoice["amount_due"] = (new_status == "UNPAID" ? naked_balance : "0.00")
      @status_over_ride = new_status
    end

    def test_pending_status
      return @status_over_ride if !@status_over_ride.nil? #explicit status over ride 
      
      return "PENDING" if pending_amount > 0 #invoice paid, the payment batch waiting to close in dynamics
      
      return "UNPAID" if naked_balance > 0 #invoice has an unpaid balance 
      
      "PAID" if naked_balance == 0 #there is no balance on this invoice, must be paid 

      #react testng - simulate closing a batch in Dynamics 
      #***REMOVE FOR PRODUCTION / WHEN DOING PRODUCTION TEST***
      #if !date_paid_on.nil? && date_paid_on < 5.minutes.ago 
      #  "PAID"
      #else
      #  res
      #end 
    end

    def status
      test_pending_status
      #naked_balance > 0 ? "UNPAID" : "PAID"
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
                "status": status,
         "naked_balance": naked_balance,
          "total_amount": total_amount,
            "amount_due": amount_due,
          "order_number": order_number,
          "paid_online": paid_online?,
          "pending_amount": pending_amount,
          "is_offline_invoice": is_offline_invoice?
      }
    end

    private

    def parse(raw)
      JSON.parse(raw)
    end
  end
end

module Dynamics
    class FinanceCharge
      attr_accessor :order_number
      attr_accessor :paid_online
      attr_accessor :date_paid_on
  
      def initialize(dynamics_finance_charge_json)
        @sl_finance_charge = dynamics_finance_charge_json
      end
  
      def number
        @sl_finance_charge["invoice_number"] #dynamics API labels the finance charge number as 'invoice number'
      end
  
      def date_issued
        DateTime.parse(@sl_finance_charge["date_issued"]).strftime("%m/%d/%Y") #"2016-06-02T08:09:00"
      end
      
      def date_issued_timestamp
        DateTime.parse(@sl_finance_charge["date_issued"]).strftime("%m/%d/%Y").to_time.to_i
      end
  
      def status=(new_status)
        @sl_finance_charge["amount_due"] = (new_status == "UNPAID" ? naked_balance : "0.00")
      end
  
      def test_pending_status
        return "PENDING" if pending_amount > 0 #finance charge paid, the payment batch waiting to close in dynamics
        
        return "UNPAID" if naked_balance > 0 #finance charge has an unpaid balance 
        
        "PAID" if naked_balance == 0 #there is no balance on this finance charge, must be paid 
      end
  
      def status
        test_pending_status
        #naked_balance > 0 ? "UNPAID" : "PAID"
      end
  
      def total_amount
        "$%.2f" % @sl_finance_charge["total_amount"]
      end
  
      def amount_due
        "$%.2f" % @sl_finance_charge["amount_due"]
      end
  
      def naked_balance
        ("%.2f" % @sl_finance_charge["amount_due"]).to_f
      end
  
      def paid_online?
        paid_online == true
      end
  
      def pending_amount
        ("%.2f" % @sl_finance_charge["pending_amount"]).to_f
      end
  
      def as_json
        {
               "fc_number": number,
             "date_issued": date_issued,
                  "status": status,
           "naked_balance": naked_balance,
            "total_amount": total_amount,
              "amount_due": amount_due,
            "order_number": order_number,
            "paid_online": paid_online?,
            "pending_amount": pending_amount
        }
      end

      def raw_record
        @sl_finance_charge
      end 
  
      private
  
      def parse(raw)
        JSON.parse(raw)
      end
    end
  end
  
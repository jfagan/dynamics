module Dynamics
  class Invoice

    def initialize(dynamics_json_invoice)
      @invoice = dynamics_json_invoice
    end

    def number
      @invoice["RefNbr"]
    end

    def batch_number
      @invoice["BatNbr"]
    end

    def date_issued
      DateTime.parse(@invoice["Crtd_DateTime"]).strftime("%m/%d/%Y") #"2016-06-02T08:09:00"
    end

    def status
      naked_balance > 0 ? "UNPAID" : "PAID"
    end

    def total_amount
      "$%.2f" % @invoice["CuryOrigDocAmt"]
    end

    def amount_due
      "$%.2f" % @invoice["CuryDocBal"]
    end

    def naked_balance
      ("%.2f" % @invoice["CuryDocBal"]).to_f
    end

    def doc_type
      @invoice[:DocType]
    end

    def as_json
      {
        "invoice_number": number,
           "date_issued": date_issued,
                "status": status,
         "naked_balance": naked_balance,
          "total_amount": total_amount,
            "amount_due": amount_due,
          "batch_number": batch_number,
              "doc_type": doc_type
      }
    end

    private

    def parse(raw)
      JSON.parse(raw)
    end
  end
end

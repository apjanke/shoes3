module Shoes::LogWindow
  def setup
    stack do
      flow do
        background black
        stack :width => -260 do
          tagline "Shoes Console", :stroke => white
        end
        button "Clear", :margin => 6, :width => 80, :height => 40 do
          Shoes.log.clear
        end
        button "Copy", :margin => 6, :width => 80, :height => 40 do
          self.clipboard = Shoes.log.collect { |typ, msg, at, mid, rbf, rbl|
            "#{typ.to_s.capitalize} in #{rbf} line #{rbl} | #{at}\n" +
            "#{msg.kind_of?(Exception) ? msg.backtrace.join("\n") : msg}\n"
          }.join("\n")
        end
        button "Save", :margin => 6, :width => 80, :height => 40 do
          filename = ask_save_file
          File.open(filename, "w") { |f|
            f.write(Shoes.log.collect { |typ, msg, at, mid, rbf, rbl|
                "#{typ.to_s.capitalize} in #{rbf} line #{rbl} | #{at}\n" +
                "#{msg.kind_of?(Exception) ? msg.backtrace.join("\n") : msg}\n"
              }.join("\n"))
          } if filename
        end
      end
      @log, @hash = stack, nil
      update
      every(0.2) do
        update
      end
    end
  end
  def update
    if @hash != Shoes.log.hash
      @hash = Shoes.log.hash
      @log.clear do
        i = 0
        Shoes.log.each do |typ, msg, at, mid, rbf, rbl|
          stack do
            background "#f1f5e1" if i % 2 == 0
            inscription strong(typ.to_s.capitalize, :stroke => "#05C"), " in ", 
              span(rbf, " line ", rbl, :stroke => "#335"), " | ",
              span(at, :stroke => "#777"), 
              :stroke => "#059", :margin => 4, :margin_bottom => 0
            flow do
              stack :margin => 6, :width => 20 do
                image "#{DIR}/static/icon-#{typ}.png"
              end
              stack :margin => 4, :width => -20 do
                s = msg.to_s.force_encoding "UTF-8"
                s << "\n#{msg.backtrace.join("\n")}" if msg.kind_of?(Exception)
                para s, :margin => 4, :margin_top => 0
              end
            end
          end
          i += 1
        end
      end
    end
  end
end

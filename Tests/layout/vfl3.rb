

Shoes.app width: 350, height: 400, resizeable: true do
  stack do
    para "Test vfl parser"

    @lay = layout use: :Vfl, width: 300, height: 300 do
      edit_line "one", name: 'el1'
      button "two", name: 'but1'
    end
    @lay.start {
      metrics = {
        padding: 8
      }
      lines = [
        '|[but1]-[el1]|'
      ]
      if false
        cs = @cls.var('el1','start').cn_equal (@cls.var('but1','width'))
        puts cs.inspect
        @lay.finish([cs])
      else 
        @lay.vfl_parse lines: lines, views: @cls.contents, metrics: metrics
        constraints = @lay.vfl_constraints
        @lay.finish constraints 
      end
    }
 end
  para "After layout"
end

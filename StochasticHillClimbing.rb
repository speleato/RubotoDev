require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

ruboto_import_widgets :Button, :LinearLayout, :TextView

$activity.start_ruboto_activity "$sample_activity" do
  setTitle 'Stochastic hill climbing'

  
  
  def on_create(bundle)
    self.content_view =
        linear_layout(:orientation => :vertical) do
          button :text => 'Manual de ayuda', :width => :wrap_content, :id => 41,
                    :on_click_listener => @ManualBusqueda
		  button :text => 'Ejecutar', :width => :wrap_content, :id => 42,
                    :on_click_listener => @Ejecutar
		@text_view = text_view :text => '', :id => 43
        end
  end
  
  
  
@ManualBusqueda = proc do |view|
      @text_view.text = 'El algoritmo consiste en buscar un elemento en un espacio de búsqueda mediante la valoración de vecinos aleatorios al individuo actual. Ofrece la ventaja
	  de ser capaz de sobreponerse a algunos óptimos locales, lo cual supone una mejora a los algoritmos hill-climbing estandar. 
	  Parametros del algoritmo ejemplo:
	  -->numero de bits: 64
	  -->maximo numero de iteraciones: 1000
	  Recomendaciones
	  1/ Este algoritmo está diseñado para funcionar en dominios discretos.
	  2/ El proceso de busqueda está diseñado para busquedas locales y se recomienda su uso para optimizar soluciones ya previamente filtradas por un algoritmo de búsqueda más global
	  3/ A pesar de la mejora, en algunos casos puede quedarse atascado en óptimos locales.
	  4/ Este procedimiento puede ser aplicado a varias soluciones candidatas al unísono'
end
   
@Ejecutar = proc do |view|
	num_bits = 64
	max_iterations = 1000
	best = best = search(max_iterations, num_bits)
	@text_view.text = "Done. Best Solution: c=#{best[:cost]}, v=#{best[:vector].join}"
end


def onemax(vector)
	return vector.inject(0.0){|sum, v| sum + ((v=="1") ? 1 : 0)}
end

def random_bitstring(num_bits)
	return Array.new(num_bits){|i| (rand<0.5) ? "1" : "0"}
end

def random_neighbor(bitstring)
	mutant = Array.new(bitstring)
	pos = rand(bitstring.size)
	mutant[pos] = (mutant[pos]=='1') ? '0' : '1'
	return mutant
	end

def search(max_iterations, num_bits)
	candidate = {}
	candidate[:vector] = random_bitstring(num_bits)
	candidate[:cost] = onemax(candidate[:vector])
	max_iterations.times do |iter|
	neighbor = {}
	neighbor[:vector] = random_neighbor(candidate[:vector])
	neighbor[:cost] = onemax(neighbor[:vector])
	candidate = neighbor if neighbor[:cost] >= candidate[:cost]
	puts " > iteration #{(iter+1)}, best=#{candidate[:cost]}"
	break if candidate[:cost] == num_bits
	end
	return candidate
end
end

require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

ruboto_import_widgets :Button, :LinearLayout, :TextView

$activity.start_ruboto_activity "$sample_activity" do
  setTitle 'Random Search'

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
      @text_view.text = 'La busqueda aleatoria plantea un metodo base para la búsqueda de elementos en un espacio acotado. El algoritmo sirve de inspiración para la búsqueda aleatoria directa y adaptativa.
						 La estrategia seguida consiste en tomar soluciones aleatoriamente en el espacio de búsqueda usando una funcion de distribución probabilistica. Una vez con un conjunto de muestras, el siguiente
						 conjunto se tomará basandose en esa función de probabilidad. Este algoritmo ofrece resultados rápidos, pero tiende a atascarse en óptimos locales. Los parámetros de configuración claves serán 
						 la función de construcción de candidatos y la función de evaluación de soluciones, las cuales determinarán la velocidad y la precisión de este algoritmo.
						 Parametros del algoritmo ejemplo: 
						 --> tamaño del problema: 2
						 --> espacio de búsqueda: [-5, 5]
						 -->iteraciones máximas: 100
						 Recomendaciones:
						 1/ Ofrece soluciones aproximadas a la solución óptima en tiempos limitados siempre que se ejecute en entornos acotados pequeños. En entornos grandes su rendimiento tiende a descender
						 2/ En ocasiones puede ser usado para hallar un punto de partida mejor para algoritmos mas adecuados a las características de un problema ofreciendo una solucion inicial mejor.'
  end
  
  

@Ejecutar = proc do |view|
	problem_size = 2
	search_space = Array.new(problem_size) {|i| [-5, +5]}
	max_iter=100
	best = search(search_space, max_iter)
	@text_view.text = "Done. Best Solution: c=#{best[:cost]}, v=#{best[:vector].inspect}"
end


def objective_function(vector)
 return vector.inject(0) {|sum, x| sum + (x ** 2.0)}
end

def random_vector(minmax)
  return Array.new(minmax.size) do |i|
	minmax[i][0] + ((minmax[i][1] - minmax[i][0]) * rand())
	end
end

def search(search_space, max_iter)
  best = nil
	max_iter.times do |iter|
	  candidate = {}
	  candidate[:vector] = random_vector(search_space)
	  candidate[:cost] = objective_function(candidate[:vector])
	  best = candidate if best.nil? or candidate[:cost] < best[:cost]
	  puts " > iteration=#{(iter+1)}, best=#{best[:cost]}"
	  iteration = iter if best.nil? or candidate[:cost] < best[:cost] 
	end
  return best
end

end
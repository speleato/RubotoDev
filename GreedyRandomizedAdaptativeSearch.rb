require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

ruboto_import_widgets :Button, :LinearLayout, :TextView

$activity.start_ruboto_activity "$sample_activity" do
  setTitle 'Greedy Randomized adaptative search'

  
  
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
	@text_view.text = 'Este algoritmo consiste en el constante sampleo de soluciones procesadas mediante un algoritmo voraz para luego optimizarlas con una búsqueda local.
					   La estrategia del procedimiento se centra en el mecanismo de construcción estocástica y voraz paso a paso
					   que limita la selección y el orden de inclusión de los componentes de una solución basada en el valor que se espera que proporcione.
						 Parametros del algoritmo ejemplo: 
						 -->datos_iniciales: [[565,575],[25,185],[345,750],[945,685],[845,655],[880,660],[25,230],[525,1000],[580,1175],[650,1130],[1605,620],[1220,580],[1465,200],[1530,5],[845,680],[725,370],[145,665],[415,635],[510,875],[560,365],[300,465],[520,585],[480,415],[835,625],[975,580],[1215,245],[1320,315],[1250,400],[660,180],[410,250],[420,555],[575,665],[1150,1160],[700,580],[685,595],[685,610],[770,610],[795,645],[720,635],[760,650],[475,960],[95,260],[875,920],[700,500],[555,815],[830,485],[1170,65],[830,610],[605,625],[595,360],[1340,725],[1740,245]]
						 -->Máximo número de iteraciones:50
						 -->Máximo número de mejoras:50
						 -->Factor de voracidad: 0.3
						 Recomendaciones:
						 1/ Ofrece soluciones aproximadas a la solución óptima en tiempos limitados siempre que se ejecute en entornos acotados pequeños. En entornos grandes su rendimiento tiende a descender
						 2/ El factor de voracidad define el mecanismo de construcción de la solucion. Un factor muy cercano a 0 resultará demasiado ambicioso mientras que uno cercano a 1 será demasiado generalizado.'
end

@Ejecutar = proc do |view|
	berlin52 = [[565,575],[25,185],[345,750],[945,685],[845,655],[880,660],[25,230],[525,1000],[580,1175],[650,1130],[1605,620],[1220,580],[1465,200],[1530,5],[845,680],[725,370],[145,665],[415,635],[510,875],[560,365],[300,465],[520,585],[480,415],[835,625],[975,580],[1215,245],[1320,315],[1250,400],[660,180],[410,250],[420,555],[575,665],[1150,1160],[700,580],[685,595],[685,610],[770,610],[795,645],[720,635],[760,650],[475,960],[95,260],[875,920],[700,500],[555,815],[830,485],[1170,65],[830,610],[605,625],[595,360],[1340,725],[1740,245]]
	max_iter = 50
	max_no_improv = 50
	greediness_factor = 0.3
	best = search(berlin52, max_iter, max_no_improv, greediness_factor)
	@text_view.text = "Done. Best Solution: c=#{best[:cost]}, v=#{best[:vector].inspect}"
end


def euc_2d(c1, c2)
	Math.sqrt((c1[0] - c2[0])**2.0 + (c1[1] - c2[1])**2.0).round
end

def cost(perm, cities)
	distance = 0
	perm.each_with_index do |c1, i|
	c2 = (i==perm.size-1) ? perm[0] : perm[i+1]
	distance += euc_2d(cities[c1], cities[c2])
	end
	return distance
end

def stochastic_two_opt(permutation)
	perm = Array.new(permutation)
	c1, c2 = rand(perm.size), rand(perm.size)
	exclude = [c1]
	exclude << ((c1==0) ? perm.size-1 : c1-1)
	exclude << ((c1==perm.size-1) ? 0 : c1+1)
	c2 = rand(perm.size) while exclude.include?(c2)
	c1, c2 = c2, c1 if c2 < c1
	perm[c1...c2] = perm[c1...c2].reverse
	return perm
end

def local_search(best, cities, max_no_improv)
	count = 0
	begin
	candidate = {:vector=>stochastic_two_opt(best[:vector])}
	candidate[:cost] = cost(candidate[:vector], cities)
	count = (candidate[:cost] < best[:cost]) ? 0 : count+1
	best = candidate if candidate[:cost] < best[:cost]
	end until count >= max_no_improv
	return best
end

def construct_randomized_greedy_solution(cities, alpha)
	candidate = {}
	candidate[:vector] = [rand(cities.size)]
	allCities = Array.new(cities.size) {|i| i}
	while candidate[:vector].size < cities.size
		candidates = allCities - candidate[:vector]
		costs = Array.new(candidates.size) do |i|
		euc_2d(cities[candidate[:vector].last], cities[i])
		end
		rcl, max, min = [], costs.max, costs.min
		costs.each_with_index do |c,i|
		rcl << candidates[i] if c <= (min + alpha*(max-min))
		end
		candidate[:vector] << rcl[rand(rcl.size)]
		end
		candidate[:cost] = cost(candidate[:vector], cities)
		return candidate
end

def search(cities, max_iter, max_no_improv, alpha)
	best = nil
	max_iter.times do |iter|
	candidate = construct_randomized_greedy_solution(cities, alpha);
	candidate = local_search(candidate, cities, max_no_improv)
	best = candidate if best.nil? or candidate[:cost] < best[:cost]
	puts " > iteration #{(iter+1)}, best=#{best[:cost]}"
	end
	return best
end
end
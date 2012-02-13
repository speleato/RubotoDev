require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

ruboto_import_widgets :Button, :LinearLayout, :TextView

$activity.start_ruboto_activity "$sample_activity" do
  setTitle 'VSN'

  
  
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
	@text_view.text = 'El VNS sigue un principio de búsqueda simple: empieza con un entorno de búsqueda pequeño y cuando ha enocontrado un óptimo local va ampliando y ampliando ese entorno hasta encontrar una mejora. Una vez
	encontrada esta mejora, el proceso se repite empezando de este punto. Hay tres puntos fundamentales: 
	A/ los minimos locales se establecen para cada sistema de vecinos
	B/ Un minimo global es un mínimo local válido para todas las estructuras de vecinos existentes
	C/ Suele darse que el mínimo local de cada sistema de vecinos es muy similar al mínimo global.
	Parametros del algoritmo ejemplo: 
	  -->datos_iniciales: [[565,575],[25,185],[345,750],[945,685],[845,655],[880,660],[25,230],[525,1000],[580,1175],[650,1130],[1605,620],[1220,580],[1465,200],[1530,5],[845,680],[725,370],[145,665],[415,635],[510,875],[560,365],[300,465],[520,585],[480,415],[835,625],[975,580],[1215,245],[1320,315],[1250,400],[660,180],[410,250],[420,555],[575,665],[1150,1160],[700,580],[685,595],[685,610],[770,610],[795,645],[720,635],[760,650],[475,960],[95,260],[875,920],[700,500],[555,815],[830,485],[1170,65],[830,610],[605,625],[595,360],[1340,725],[1740,245]]
	  -->Máximo número de iteraciones:150
	  -->Máximo número de mejoras:50
	  -->Vecinos: 1..20
	  -->local_search_optima = 12000.0
	  -->Función de valoración = Multiplicador * (local_search_optima/datos_iniciales.size.to_f)
	  Recomendaciones
	  1/ Se recomienda usar algoritmos de aproximación para reducir el tiempo de ejecución.
	  2/ El heuristico utilizado para la búsqueda local debe ser específico para cada tipo de problema'
end

@Ejecutar = proc do |view|
	berlin52 = [[565,575],[25,185],[345,750],[945,685],[845,655],[880,660],[25,230],[525,1000],[580,1175],[650,1130],[1605,620],[1220,580],[1465,200],[1530,5],[845,680],[725,370],[145,665],[415,635],[510,875],[560,365],[300,465],[520,585],[480,415],[835,625],[975,580],[1215,245],[1320,315],[1250,400],[660,180],[410,250],[420,555],[575,665],[1150,1160],[700,580],[685,595],[685,610],[770,610],[795,645],[720,635],[760,650],[475,960],[95,260],[875,920],[700,500],[555,815],[830,485],[1170,65],[830,610],[605,625],[595,360],[1340,725],[1740,245]]
	max_no_improv = 50
	max_no_improv_ls = 70
	neighborhoods = 1...20
	best = search(berlin52, neighborhoods, max_no_improv, max_no_improv_ls)
	@text_view.text = "Done. Best Solution: c=#{best[:cost]}, v=#{best[:vector].inspect}"
end


def euc_2d(c1, c2)
	Math.sqrt((c1[0] - c2[0])**2.0 + (c1[1] - c2[1])**2.0).round
end

def cost(perm, cities)
	distance =0
	perm.each_with_index do |c1, i|
	c2 = (i==perm.size-1) ? perm[0] : perm[i+1]
	distance += euc_2d(cities[c1], cities[c2])
	end
	return distance
end

def random_permutation(cities)
	perm = Array.new(cities.size){|i| i}
	perm.each_index do |i|
	r = rand(perm.size-i) + i
	perm[r], perm[i] = perm[i], perm[r]
	end
	return perm
end

def stochastic_two_opt!(perm)
	c1, c2 = rand(perm.size), rand(perm.size)
	exclude = [c1]
	exclude << ((c1==0) ? perm.size-1 : c1-1)
	exclude << ((c1==perm.size-1) ? 0 : c1+1)
	c2 = rand(perm.size) while exclude.include?(c2)
	c1, c2 = c2, c1 if c2 < c1
	perm[c1...c2] = perm[c1...c2].reverse
	return perm
end

def local_search(best, cities, max_no_improv, neighborhood)
	count = 0
	begin
		candidate = {}
		candidate[:vector] = Array.new(best[:vector])
		neighborhood.times{stochastic_two_opt!(candidate[:vector])}
		candidate[:cost] = cost(candidate[:vector], cities)
		if candidate[:cost] < best[:cost]
			count, best = 0, candidate
		else
			count += 1
		end
	end until count >= max_no_improv
	return best
end

def search(cities, neighborhoods, max_no_improv, max_no_improv_ls)
	best = {}
	best[:vector] = random_permutation(cities)
	best[:cost] = cost(best[:vector], cities)
	iter, count = 0, 0
	begin
		neighborhoods.each do |neigh|
		candidate = {}
		candidate[:vector] = Array.new(best[:vector])
		neigh.times{stochastic_two_opt!(candidate[:vector])}
		candidate[:cost] = cost(candidate[:vector], cities)
		candidate = local_search(candidate, cities, max_no_improv_ls, neigh)
		puts " > iteration #{(iter+1)}, neigh=#{neigh}, best=#{best[:cost]}"
		iter += 1
		if(candidate[:cost] < best[:cost])
			best, count = candidate, 0
			puts "New best, restarting neighborhood search."
			break
		else
			count += 1
		end
 		end
	end until count >= max_no_improv
return best
end

end
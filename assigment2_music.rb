# Welcome to Sonic Piuse_random_seed(1001)
# Simple input melody represented as a list of MIDI note numbers
use_random_seed(0)
#use_random_seed Time.now.to_i
input_melody=[60, 64, 67, 72, 67, 64, 60, 55, 60, 64, 67, 72]
input_melody2=[10,9,7,4,10,9,7,4,10,9,7,4, 5,7,8,7,5,4,5,8,7,5,4,5,3,3,10,9,7,5,7,8,8]
input_melody3=[5,7,8,7,5,4,5,8,7,5,4,5,3,3,10,9,7,5,7,8,8]#,3,7,6,7]



T = 2.6


# Build a Markov model from the input melody
define :build_markov_model do |input_melody |
  model = {}
  (input_melody.length-1).times do |i|
    context=input_melody[i]
    next_note = input_melody[i+1]
    if model.include? context
      model[context].append(next_note)
    else
      model[context]=[next_note]
    end
  end
  model
end

define :generate_melody do |model, start_note,length|
  melody=start_note.dup
  (length-1).times do
    context = melody[-1]
    if model.include? context
      next_note=model[context].choose
      melody.append(next_note)
    else
      break
    end
  end
  melody
end

def is_para a, b
  if (a<=>b) !=0
    (0..a.length-2).each do |i|
      ((i+1)..b.length-1).each do |j|
        if(a[j]-a[i]==4 && b[j]-b[i]==4) || (a[j]-a[i]==7 && b[j]-b[i]==4)
          return true
        end
      end
    end
  end
  return false
end



markov_model=build_markov_model(input_melody2)
markov_model2=build_markov_model(input_melody3)

puts markov_model

new_melody=generate_melody(markov_model, [10], 32)
new_melody2=generate_melody(markov_model2, [5], 32)
new_melody3=generate_melody(markov_model2, [7], 32)


# State machine utility functions
define :markov do |a, h|
  h[a].sample;
end # Chooses the next state at  random from hash

define :g do |k|
  get[k];
end # simplified root note in scale getter

define :s do |k, n|
  set k, n;
end # simplified root note setter


define :mnote do |key,chain|
  s key, (markov (g key), chain);
  g key;
end

set :k, 0
set :s, 0

K = {
  0 => [0,1],
  1 => [0,1]
}

S = {
  0 => [1,0,0,0, 0,0,0,0, 0,0,0,0], # 1/8 chance of choosing snare pattern 2
  1 => [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1] # 1/16 chance of choosing snare pattern 2
}

kick_patterns = [
  (bools, 1,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0), # Kick Pattern 1 / C
  (bools, 1,0,0,0, 0,0,1,0, 0,1,1,0, 0,1,1,0) # Kick Pattern 2 / C
].ring

snare_patterns = [
  (bools, 0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0), # Snare Pattern 1 / G
  (bools, 1,1,1,1, 1,0,1,0, 0,0,0,0, 1,0,1,0)  # Snare Pattern 2 / G
].ring

print mnote :k, K






POP_SIZE = 10
GENS = 10
MUT_RATE = 0.1
input_melody=[10,9,7,4,10,9,7,4,10,9,7,4]#[5,7,8,7,5,4,5,8,7,5,4,5,3,3,10,9,7,5,7,8,8]

# Define the fitness function
define :fitness do |seq|
  score = 0
  # Calculate the score based on some criteria
  # For example, you could reward sequences that have a certain number of beats or a specific pattern
  # Here's a simple fitness function that just counts the number of beats
  seq.each do |beat|
    score += 1 if input_melody.include?(seq)
  end
  return score
end

# Define the initial population
population = Array.new(POP_SIZE) { Array.new(16) { [10,11,9,12,8,11,11,13,13,12,13,14,15,13,15,14].sample } }

# Run the genetic algorithm for a set number of generations
best_indi=[]
GENS.times do |gen|
  puts "Generation #{gen}"
  
  # Evaluate the fitness of each individual in the population
  fitness_scores = population.map { |ind| fitness(ind) }
  
  # Select the fittest individuals to be parents for the next generation
  parents = []
  2.times do
    parent_index = fitness_scores.index(fitness_scores.max)
    parents.push(population[parent_index])
    fitness_scores.delete_at(parent_index)
    population.delete_at(parent_index)
  end
  
  # Generate the next generation by crossing over and mutating the parents
  children = []
  (POP_SIZE - 2).times do
    child = []
    parents[0].each_with_index do |gene, index|
      child.push((gene + parents[1][index]) / 2) # Crossover
      if rand < MUT_RATE # Mutation
        child[index] = 1 - child[index]
      end
    end
    children.push(child)
  end
  
  # Add the parents back to the population
  population += parents
  # Add the children to the population
  population += children
  
  # Play the fittest individual from the current generation
  best_index = fitness_scores.index(fitness_scores.max)
  best_individual = population[best_index]
  puts "Best fitness: #{fitness_scores.max}"
  best_indi=best_individual
  
  
  #sleep 2
end


scl2=scale(:c5,:major,num_octaves:3)

all_id=0

with_fx :reverb, mix: 0.75, damp: 0.9 do
  live_loop :melody do
    use_synth :piano
    if(all_id<96 || (all_id>256 and all_id<317))
      play new_melody.map{|n| scl2[n]}.tick, amp:0.8+(all_id%16)*0.3, release: 1.5
      #play new_melody.map{|n| scl2[-n]}.tick, amp:0.8+(all_id%16)*0.2, release: 1.5
    elsif (all_id<192)
      play new_melody2.map{|n| scl2[n]}.tick, amp:5-(all_id%8)*0.35, release: 1.5
      if ((all_id>160 and all_id<168) || (all_id>174 and all_id<192))
        play new_melody2.map{|n| scl2[-n]}.look, amp:5-(all_id%16)*0.05, release: 1.5
      end
    elsif (all_id<317)
      play new_melody3.map{|n| scl2[n]}.tick, amp:5-(all_id%8)*0.35, release: 1.5
      if ((all_id>192 and all_id<200) || (all_id>208 and all_id<224))# and all_id<168) || (all_id>174 and all_id<192))
        play new_melody2.map{|n| scl2[-n]}.look, amp:5-(all_id%16)*0.05, release: 1.5
        #play best_indi.map{|n| scl2[n]}.look, amp:3-(all_id%16)*0.05, release: 1.5
      end
    end
    
    sleep T/16
    
    all_id+=1
  end
end




sleep 2*T


#for chord
chord_pat=[0,2,4,7].ring
rhythm_pat=[0.25]*4
scl=scale(:C4, :major, num_octaves:3)
sequence=[3,4,2,5]*4
chord_pat=[0,2,4,7].ring
scl=scale(:C3, :major, num_octaves:3)
voicing=[
  #root pos
  [
    [0,2,4,7].ring,
    [0,4,7,9].ring,
    [0,2,7,9].ring,
    [0,4,9,1].ring,
    [0,2,4,11].ring
  ],
  [
    [2,4,7,9].ring,
    [2,7,9,11].ring,
    [2,9,11,14].ring,
    [2,4,7,11].ring,
    [2,4,9,11].ring
  ],
  [
    [4,7,9,11].ring,
    [4,7,11,14].ring,
    [4,9,11,14].ring,
    [4,11,4,16].ring
    
  ]
]

i=0

last_chord_pat=voicing[1].choose


with_fx :reverb, mix: 0.5 do
  live_loop :chord do
    deg=sequence[i%4]
    
    this_chord_pat=voicing[rand_i(3)].choose
    four_voice_chord = scl.values_at(*(last_chord_pat+deg))
    
    use_synth :bass_foundation
    
    last_chord=last_chord_pat + sequence[-1]
    
    while is_para last_chord, four_voice_chord
      idx=rand_i(3)+1
      arr=four_voice_chord.to_a
      arr[idx]=(arr[idx]+7)%21
      four_voice_chord=arr.sort.ring
    end
    
    last_chord_pat=this_chord_pat
    
    play four_voice_chord, amp:1.15
    play_pattern_timed four_voice_chord, T/16, amp:1.15
    i+=1
    #sleep 0.25
  end
  
end


id=0
live_loop :snares do
  pat=snare_patterns[1]
  if id!=0
    pat = snare_patterns[mnote :s, S] # markov select pattern
  end
  id+=1
  
  pat.length.times do
    sample :sn_dolf, amp: 0.5  if pat.tick
    sleep T/16
  end
end


live_loop :kicks do
  pat = kick_patterns[mnote :k, K] # markov select pattern
  pat.length.times do
    sample :bd_zum, amp: 1.5 if pat.tick
    sleep T/16
  end
end


seq2=[10,11,9,12,8,11,11,7]

seq3=[10,11,9,12,8,11,11,13,13,12,13,14,15,13,15,14]

seq4=[13,12,13,14,15,13,15,14]

sleep 2*T

i2=0

live_loop :bigchord do
  deg=seq2[i2%8]
  deg2=seq3[i2%16]
  #deg2=best_indi[i2%16]
  use_synth :dsaw
  note=scl.values_at(deg2)
  if(i2<32)
    note=scl.values_at(deg)
  end
  
  if(i2<48)
    play_pattern_timed note, T/4, amp: 0.5, release: 4
    i2+=1
  end
end


##| input_melody.each do |note|
##|   play note
##|   sleep 0.5
##| end










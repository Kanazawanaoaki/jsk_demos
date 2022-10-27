from kotodama import kotodama

# auxiliary_verbはset型で何個も引数を持たせて構わない
auxiliary_verb = {"過去","自分の希望"}
verb = "過ごす"
print(kotodama.transformVerb(verb,auxiliary_verb))
# output 過ごしたかった


# auxiliary_verb = {"受け身"}
# auxiliary_verb = {"受け身","過去"}
auxiliary_verb = {"過去"}
verb = "混ざる"
# verb = "混ぜる"
# verb = "する"
print(kotodama.transformVerb(verb,auxiliary_verb))

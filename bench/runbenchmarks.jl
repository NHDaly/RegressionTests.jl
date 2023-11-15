using RegressionTests
using Chairmarks

# TODO: handle interruption well even with this naughty code
# try
#     while true
#         println("Infinite loop...")
#         sleep(.1)
#     end
# catch x
#     println("Caught exception: $x")
#     try
#         disable_sigint() do
#             while true
#                 println("Can't stop me now!")
#                 sleep(.01)
#             end
#         end
#     finally
#         println("???")
#     end
# end

# 463.5 => 306.8 => 52.3
for n in 1:50
    # @track begin
    #     res = @be n rand seconds=.01
    #     [minimum(res).time, Chairmarks.median(res).time, Chairmarks.mean(res).time]
    # end
    @group begin
        res = @be n rand
        @track minimum(res).time
        @track Chairmarks.median(res).time
        @track Chairmarks.mean(res).time
    end
end

for k in 1:1_000_000
    @track k
end

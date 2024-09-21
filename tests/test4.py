class TicketBooking:
    def __init__(self) -> None:
        self.seats:list[bool] = [False, False, False, False, False, False, False, False, False, False]

    def book_ticket(self) -> None:
        for i in range(10):
            if not self.seats[i]:
                self.seats[i] = True
                # print(f"Ticket booked successfully! Seat number: {i + 1}")
                print("Ticket booked successfully! Seat number:")
                print(i + 1)
                break
        else:
            print("Sorry, no seats available.")

    def cancel_ticket(self, seat_number: int) -> None:
        if self.seats[seat_number - 1]:
            self.seats[seat_number - 1] = False
            print("Ticket cancelled successfully!")
            
        else:
            print("Seat number") 
            print(seat_number)
            print("is already vacant.")

    def display_available_seats(self) -> None:
        for i in range(10):
            if not self.seats[i]:
                print("Seat number:")
                print(i + 1)
                print("is available.")
            else:
                print("Seat number:")
                print(i + 1)
                print("is not available.")
                
                
                
def main():
    tb:TicketBooking = TicketBooking()
    tb.book_ticket()
    tb.book_ticket()
    tb.book_ticket()
    tb.cancel_ticket(2)
    tb.display_available_seats()
    
if(__name__ == "__main__"):
    main()
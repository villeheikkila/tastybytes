export interface IProduct {
  id: string;
  name: string;
  producer: string;
  category: any;
  subCategory: any;
}

export interface IProductObject {
  product: IProduct;
}

export interface IProductCard {
  product: IProduct;
}
export interface IProductProps {
  product: IProduct;
}
export interface IUser {
  firstName: string;
  lastName: string;
  email: string;
  id: string;
}

export interface IUserList {
  users: IUser[];
}

export interface IProductList {
  products: IProduct[];
}

export interface ILogIn {
  setToken: any;
}

export interface Token {
  setToken: any;
}

export interface INavbar {
  setToken: any;
}

export interface IUserObject {
  user: IUser | null;
}

export interface INotificationContentWrapper {
  className?: string;
  message?: string;
  onClose?: () => void;
  variant: "success" | "warning" | "error" | "info";
}

export interface INotification {
  message: string;
  variant: any;
}

export interface INotificationObject {
  notification: INotification;
}

export interface OptionType {
  label: string;
  value: string;
}

export interface IConfirmationDialog {
  content: string;
  title: string;
  description: string;
  declineButton: string;
  acceptButton: string;
  visible: boolean;
  setVisible: any;
  onAccept: any;
}

export interface ICreateCheckIn {
  authorId: string;
  productId: string;
}
